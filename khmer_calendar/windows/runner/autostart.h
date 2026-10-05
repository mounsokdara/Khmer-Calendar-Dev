#ifndef RUNNER_AUTOSTART_H_
#define RUNNER_AUTOSTART_H_

// HKCU Run key + Startup folder + StartupApproved (Settings / Task Manager).
bool KhmerAutostartEnable();
bool KhmerAutostartDisable();
bool KhmerAutostartIsEnabled();

#endif  // RUNNER_AUTOSTART_H_
