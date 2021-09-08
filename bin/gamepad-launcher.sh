#!/bin/bash

THIS_SCRIPT="$(which $0)"
SERVICE_NAME="gamepad-launcher.service"
OVERRIDE_PATH="20-path.conf"
OVERRIDE_LAUNCH="40-launch.conf"
OVERRIDE_CLEANUP="60-cleanup.conf"

# Display usage statement and exit unsuccessfully.
usage(){
	echo "usage: $0 action [args...]"
	echo "  actions:"
	echo "    launch [( --clear | command [args...] )]"
	echo "    cleanup [( --clear | command [args...] )]"
	echo "    suggestions"

	exit 1
}

# Handle the suggestions action.
suggestions(){
	echo "Launch: each application is first presented as its command if installed"
	echo "directly, then as a Flatpak command if applicable. Don't forget to use"
	echo "flatpak --user run ... if you installed an application in per-user mode."
	echo "  Steam (Big Picture Mode):"
	echo "    steam -tenfoot"
	echo "    flatpak run com.valvesoftware.Steam -tenfoot"
	echo "  SteamLink:"
	echo "    steamlink"
	echo "    flatpak run com.valvesoftware.SteamLink"
	echo
	echo "Cleanup: these commands are primarily used to turn off gamepads when an"
	echo "application exits."
	echo "  Turn off gamepads using the xow driver (requires NOPASSWD setup):"
	echo "    sudo systemctl restart xow"

	exit 0
}

# Set the PATH variable for the service.
set_path(){
	# Find the path to store the override file.
	local override_file="$(get_override_file $OVERRIDE_PATH)"

	# Without writing the user's current path into the service definitions,
	# some systems don't have the full path (for example, /usr/games and
	# /usr/local/games may be absent).
	echo -e "[Service]\nEnvironment=PATH="\""$PATH"\" > "$override_file"
	[[ $? -ne 0 ]] && exit $?
}

# Handle the launch action.
launch(){
	# Find the path to store the override file; exit if none exists.
	local override_file="$(get_override_file $OVERRIDE_LAUNCH)"

	if [[ $# -eq 0 ]]; then
		# If no more arguments, then open the override file for manual editing.
		${EDITOR:-vi} "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	elif [[ $1 = "--clear" ]] && [[ -f "$override_file" ]]; then
		# Delete the override file, confirming first.
		echo "To clear the launch application, confirm deletion of the config file:"
		rm -i "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	elif [[ $1 = "--clear" ]]; then
		# Nothing to be done.
		echo "No launch config file to be removed."
		exit 0
	else
		# Write to the file, writing the path first.
		set_path
		echo -e "[Service]\nExecStart=-$(which $1) ${@:2}" > "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	fi
}

# Handle the cleanup action.
cleanup(){
	# Find the path to store the override file; exit if none exists.
	local override_file="$(get_override_file $OVERRIDE_CLEANUP)"

	if [[ $# -eq 0 ]]; then
		# If no more arguments, then open the override file for manual editing.
		${EDITOR:-vi} "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	elif [[ $1 = "--clear" ]] && [[ -f "$override_file" ]]; then
		# Delete the override file, confirming first.
		echo "To clear the cleanup command(s), confirm deletion of the config file:"
		rm -i "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	elif [[ $1 = "--clear" ]]; then
		# Nothing to be done.
		echo "No cleanup config file to be removed."
		exit 0
	else
		# Write to the file, writing the path first.
		set_path
		echo -e "[Service]\nExecStopPost=-$(which $1) ${@:2}" >> "$override_file" &&
			systemctl --user daemon-reload
		exit $?
	fi
}

# Find (or make) the filename to use for the specified override file.
get_override_file(){
	local unit_paths=$(systemctl --user show -p UnitPath --value | tr " " "\n" | grep -v /run/)
	# Does the file already exist somewhere?
	for unit_path in $unit_paths; do
		if [[ -f "$unit_path/$SERVICE_NAME.d/$1" ]]; then
			echo "$unit_path/$SERVICE_NAME.d/$1"
			return 0
		fi
	done
	# Do any paths already have a writable $SERVICE_NAME.d subdirectory?
	for unit_path in $unit_paths; do
		if [[ -d "$unit_path/$SERVICE_NAME.d" ]] && [[ -w "$unit_path/$SERVICE_NAME.d" ]]; then
			echo "$unit_path/$SERVICE_NAME.d/$1"
			return 0
		fi
	done
	# Do any writable paths already exist?
	for unit_path in $unit_paths; do
		if [[ -d "$unit_path" ]] && [[ -w "$unit_path" ]]; then
			mkdir -p "$unit_path/$SERVICE_NAME.d"
			echo "$unit_path/$SERVICE_NAME.d/$1"
			return 0
		fi
	done
	# Attempt to make each path.
	for unit_path in $unit_paths; do
		if mkdir -p "$unit_path/$SERVICE_NAME.d" &> /dev/null; then
			echo "$unit_path/$SERVICE_NAME.d/$1"
			return 0
		fi
	done

	>&2 echo "No path available for conf files."
	exit 1
}

# ***MAIN***

# Check that there is at least one parameter.
[[ $# -eq 0 ]] && usage

# Determine which action to perform.
case $1 in
	"launch")
		launch ${@:2}
		;;
	"cleanup")
		cleanup ${@:2}
		;;
	"suggestions")
		suggestions $0
		;;
	*)
		usage
		;;
esac
