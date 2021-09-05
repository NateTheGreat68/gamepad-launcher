# gamepad-launcher
A simple way to launch an application when a gamepad connects

## Overview
Note: as it currently exists, this is written for and only tested on a particular Debian 11 system. It may or may not work on others without modification.

There are two parts: 
* a udev rule
  * The udev rule triggers when a device mapped to /dev/input/js0 is added to the system.
  * It attempts to start a systemd user unit called `steam_bigpicture.service` when triggered.
* a systemd service unit
  * The systemd service is intended to be run by a systemd user instance.
  * It can be modified to run another application if desired by changing its `ExecStart=` line.

## Installation
Manual installation is as follows:
```shell
$ mkdir -p ~/.config/systemd/user
$ cp systemd/steam_bigpicture.service ~/.config/systemd/user/
$ systemctl --user daemon-reload
# cp udev/99-controller.rules /etc/udev/rules.d/
# udevadm control --reload
```
