#include "autostart.h"

#include <glib.h>
#include <glib/gstdio.h>
#include <unistd.h>

#include <string>

namespace {

constexpr const char kDesktopId[] = "com.mounsokdara.khmercalendar.desktop";

std::string ExePath() {
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
  if (n <= 0) {
    return std::string();
  }
  buf[n] = '\0';
  return std::string(buf);
}

std::string DesktopPath() {
  const char* dir = g_get_user_config_dir();
  if (dir == nullptr || dir[0] == '\0') {
    return std::string();
  }
  gchar* path = g_build_filename(dir, "autostart", kDesktopId, nullptr);
  std::string out(path);
  g_free(path);
  return out;
}

bool WriteDesktop() {
  std::string exe = ExePath();
  std::string dest = DesktopPath();
  if (exe.empty() || dest.empty()) {
    return false;
  }
  gchar* folder = g_path_get_dirname(dest.c_str());
  g_mkdir_with_parents(folder, 0755);
  g_free(folder);

  g_autoptr(GKeyFile) kf = g_key_file_new();
  g_key_file_set_string(kf, "Desktop Entry", "Type", "Application");
  g_key_file_set_string(kf, "Desktop Entry", "Version", "1.0");
  g_key_file_set_string(kf, "Desktop Entry", "Name", "Khmer Calendar");
  g_key_file_set_locale_string(kf, "Desktop Entry", "Name", "km",
                               "ប្រតិទិនខ្មែរ");
  g_key_file_set_string(kf, "Desktop Entry", "Comment",
                        "Khmer lunar calendar");
  gchar* exec = g_strdup_printf("\"%s\" --autostart", exe.c_str());
  g_key_file_set_string(kf, "Desktop Entry", "Exec", exec);
  g_free(exec);
  g_key_file_set_string(kf, "Desktop Entry", "TryExec", exe.c_str());
  g_key_file_set_string(kf, "Desktop Entry", "Categories",
                        "Utility;Calendar;Education;");
  g_key_file_set_string(kf, "Desktop Entry", "StartupWMClass",
                        "com.mounsokdara.khmercalendar");
  g_key_file_set_boolean(kf, "Desktop Entry", "Terminal", FALSE);
  g_key_file_set_boolean(kf, "Desktop Entry", "StartupNotify", FALSE);
  g_key_file_set_boolean(kf, "Desktop Entry", "Hidden", FALSE);
  g_key_file_set_boolean(kf, "Desktop Entry", "DBusActivatable", FALSE);
  g_key_file_set_boolean(kf, "Desktop Entry", "X-GNOME-Autostart-enabled",
                         TRUE);
  g_key_file_set_integer(kf, "Desktop Entry", "X-GNOME-Autostart-Delay", 2);

  g_autoptr(GError) error = nullptr;
  gboolean ok = g_key_file_save_to_file(kf, dest.c_str(), &error);
  if (!ok) {
    g_warning("autostart write failed: %s",
              error != nullptr ? error->message : "unknown");
  }
  return ok == TRUE;
}

bool RemoveDesktop() {
  std::string dest = DesktopPath();
  if (dest.empty()) {
    return true;
  }
  if (!g_file_test(dest.c_str(), G_FILE_TEST_EXISTS)) {
    return true;
  }
  return g_remove(dest.c_str()) == 0;
}

bool DesktopEnabled() {
  std::string dest = DesktopPath();
  if (dest.empty() || !g_file_test(dest.c_str(), G_FILE_TEST_IS_REGULAR)) {
    return false;
  }
  g_autoptr(GKeyFile) kf = g_key_file_new();
  g_autoptr(GError) error = nullptr;
  if (!g_key_file_load_from_file(kf, dest.c_str(), G_KEY_FILE_NONE, &error)) {
    return false;
  }
  if (g_key_file_get_boolean(kf, "Desktop Entry", "Hidden", nullptr)) {
    return false;
  }
  if (g_key_file_has_key(kf, "Desktop Entry", "X-GNOME-Autostart-enabled",
                         nullptr) &&
      !g_key_file_get_boolean(kf, "Desktop Entry",
                              "X-GNOME-Autostart-enabled", nullptr)) {
    return false;
  }
  return true;
}

void RespondBool(FlMethodCall* call, bool value) {
  g_autoptr(FlValue) v = fl_value_new_bool(value);
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(v));
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("autostart reply failed: %s",
              error != nullptr ? error->message : "unknown");
  }
}

void MethodCb(FlMethodChannel* /*channel*/, FlMethodCall* call,
              gpointer /*data*/) {
  const gchar* method = fl_method_call_get_name(call);
  if (g_strcmp0(method, "enable") == 0) {
    RespondBool(call, WriteDesktop() && DesktopEnabled());
    return;
  }
  if (g_strcmp0(method, "disable") == 0) {
    RemoveDesktop();
    RespondBool(call, !DesktopEnabled());
    return;
  }
  if (g_strcmp0(method, "isEnabled") == 0) {
    RespondBool(call, DesktopEnabled());
    return;
  }
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(call, response, nullptr);
}

}  // namespace

FlMethodChannel* khmer_autostart_channel_new(FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      messenger, "khmer.autostart", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, MethodCb, nullptr,
                                            nullptr);
  return channel;
}
