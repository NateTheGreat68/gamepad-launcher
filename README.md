# gamepad-launcher
A simple way to launch an application when a gamepad connects

## Overview
Note: as it currently exists, this is written for and only tested on a particular Debian 11 system. It may or may not work on others without modification.

There are three components:
* a udev rule
  * The udev rule triggers when a device mapped to /dev/input/js0 is added to the system.
  * It attempts to start a systemd user unit called `gamepad_launcher.service` when triggered.
* the main systemd service unit
  * The systemd service is intended to be run by a systemd user instance.
  * If xow (github.com/medusalix/xow) is installed and the user has permissions (see below), it will be restarted when the service stops to turn off controllers.
  * Otherwise, this service doesn't *do* anything - it's meant for other services to attach onto and start with.
* a set of systemd service units for common applications
  * These service are also intended to be run by a systemd user instance.
  * If the desired application isn't included, an existing service file can be used as a template.
  * The desired service must be enabled manually during installation. Only one service can be enabled at a time; there are no checks to prevent collisions.

## Application service files provided
* `steam_bigpicture.service` for "natively"-installed Steam.
* `steam_bigpicture.flatpak.service` for Flatpak-installed Steam.
* `steam_bigpicture.flatpak.peruser.service` for Flatpak per-user-installed Steam (`flatpak --user install ...`).
* `steamlink.service` for "natively"-install SteamLink (I think this is only applicable to Raspberry Pis).
* `steamlink.flatpak.service` for Flatpak-installed SteamLink.
* `steamlink.flatpak.peruser.service` for Flatpak per-user-install SteamLink (`flatpak --user install ...`).

## Installation
Manual installation is as follows:
```shell
$ mkdir -p ~/.config/systemd/user
$ cp systemd/* ~/.config/systemd/user/
$ systemctl --user enable <selected_application_service.service>
$ systemctl --user daemon-reload
# cp udev/99-gamepads.rules /etc/udev/rules.d/
# udevadm control --reload
```

## Automatically turning off controllers with xow
Restarting the xow service, if used (to connect Xbox One / Series controllers to the USB wireless dongle), should turn the controllers off. However, restarting the service normally requires root permissions.
To get around this, a NOPASSWD line can be added to the sudoers file (or an included file in the appropriate directory).
The recommended way is to run `sudo visudo /etc/sudoers.d/gamepads` and add the following line:
```
%video ALL = (root) NOPASSWD: /usr/bin/systemctl restart xow
```
and then any user who is a member of the group "video" should be able to restart xow without a password.
Explaining why the visudo command should be used is outside the scope of this README; just know that you risk seriously screwing up your system if you don't.
