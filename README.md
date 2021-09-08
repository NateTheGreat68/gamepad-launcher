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
  * By default, this service doesn't *do* anything - it's meant for other services to attach onto and start with, or to be extended via systemd override conf files.
* a script for configuring the behavior of the launcher
  * gamepad-launcher.sh can set or clear the launch or cleanup behaviors of the service by managing override files.
  * Usage is described below.

## Installation
Installation is as follows:
```shell
$ sudo make install
$ sudo udevadm control --reload
$ systemctl --user daemon-reload
```

## Configuring the service
The service is broken into two parts:
* launch
  * launch can be configured to run one application, for example steam, when the service is started.
  * To set an application to launch, run `$ gamepad-launcher.sh launch <command> [args...]`; for example `$ gamepad-launcher.sh launch steam -tenfoot`.
  * Run `$ gamepad-launcher.sh launch --clear` to not launch anything.
  * Run `$ gamepad-launcher.sh launch` to edit the systemd service unit override file manually.
  * The application must block execution (must not fork). Once the application exits successfully, cleanup begins.
  * If the service is not configured to launch an application, it will immediately begin cleanup after it starts.
  * Only one launch application can be configured at a time. Specifying a new one will remove the previous one.
* cleanup
  * cleanup can be configured to run one or more commands, for example restarting xow to turn off connected controllers (see below).
  * To add a cleanup command, run `$ gamepad-launcher.sh cleanup <command> [args...]`; for example, `$ gamepad-launcher.sh cleanup sudo systemctl restart xow`.
  * Run `$ gamepad-launcher.sh cleanup --clear` to remove all cleanup commands.
  * Run `$ gamepad-launcher.sh cleanup` to edit the systemd service unit override file manually.
  * Multiple cleanup commands can be present; they will all be run sequentially when the service is stopping. Specifying a new one will add to the list automatically.

## Application suggestions
Running `$ gamepad-launcher.sh suggestions` will provide a list of common launch applications and cleanup commands. Feel free to suggest or request additional ones as a GitHub issue.

## Automatically turning off controllers with xow
Restarting the xow service, if used (to connect Xbox One / Series controllers to the USB wireless dongle), should turn the controllers off. However, restarting the service normally requires root permissions.
To get around this, a NOPASSWD line can be added to the sudoers file (or an included file in the appropriate directory).

The recommended way is to run `sudo visudo /etc/sudoers.d/gamepads` and add the following line:
```
%video ALL = (root) NOPASSWD: /usr/bin/systemctl restart xow
```
and then any user who is a member of the group "video" should be able to restart xow without a password.

Explaining why the visudo command should be used is outside the scope of this README; just know that you risk seriously screwing up your system if you don't.
