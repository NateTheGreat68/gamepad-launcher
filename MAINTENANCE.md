# gamepad-launcher

NOTE: Significant parts of this file are no longer accurate due to changes in the codebase. It is still being included because it explains some important aspects of the decision-making with regards to the program's behavior.

## Explanation of file layout and working principles
The goal is to launch a user-selected application when a gamepad connects to the system, then run some cleanup when the application exits.

Disconnection of one or more gamepads should *not* exit the application - this would be an undesired result because, for an example, an idle gamepad could kill a game.

This means that an application must either: 
* block execution and then run the cleanup; or
* implement, within its systemd service unit, a check that the application is still running and then run cleanup when it exits.

Cleanup currently only includes sending a signal to turn off gamepads (when the device/driver makes this possible) then stopping the main service (so it can be started again the next time a gamepad connects). The only gamepads which can be turned off from the command line at this time are Xbox controllers connected via a USB wireless dongle and the xow driver; more will be added as available.

To achieve this, a udev rule starts a systemd user service unit called gamepad_launcher.service. Although this service doesn't start anything directly, it accomplishes two things:
* It acts as generic unit to be started by the udev rule. This is desirable because root permissions are required to modify udev rules, whereas using a systemd user unit allows an unprivileged user to attach any desired services to it (by making gamepad_launcher.service WantedBy the other service(s) and then enabling them with `$ systemctl --user ...`). Different users can even easily launch different applications this way.
* When stopped, it runs the commands that turn off gamepads. This is the primary reason it is a oneshot service rather than a target unit.

This does have one fatal flaw which may need to be addressed eventually: if the application's service unit does not stop gamepad_launcher.service when it exits, gamepad_launcher will remain active and will need to be manually stopped in order to be started again the next time a gamepad is connected. The application service units in this repo implement this by calling `systemctl --user stop gamepad_launcher.service` on ExecStopPost. This is clunky, but the better option - the PropagatesStopTo directive - was introduced in systemd version 249, released 2021-07-09, and is too new to expect it to work on most systems. The PartOf directive performs the opposite of the desired outcome - it would stop the application service if the launcher service stopped, but not vice versa.
