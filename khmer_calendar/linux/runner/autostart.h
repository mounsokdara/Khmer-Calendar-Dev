#ifndef RUNNER_AUTOSTART_H_
#define RUNNER_AUTOSTART_H_

#include <flutter_linux/flutter_linux.h>

// XDG autostart: ~/.config/autostart/com.mounsokdara.khmercalendar.desktop
FlMethodChannel* khmer_autostart_channel_new(FlView* view);

#endif  // RUNNER_AUTOSTART_H_
