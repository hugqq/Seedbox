#!/usr/bin/env bash
tput sgr0; clear

SEEDBOX_INSTALLATION_URL="https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/components/seedbox_install.sh"
QB_INSTALL_URL="https://raw.githubusercontent.com/hugqq/Seedbox/refs/heads/main/components/qBittorrent_install.sh"

if ! command -v curl >/dev/null 2>&1; then
	echo "curl is required to load online components"
	exit 1
fi

## Load Seedbox Components
source <(curl -fsSL "$SEEDBOX_INSTALLATION_URL")
# Check if Seedbox Components is successfully loaded
if [ $? -ne 0 ]; then
	echo "Component ~Seedbox Components~ failed to load"
	echo "Check connection with GitHub"
	exit 1
fi

if ! declare -F uninstall_seedbox_ >/dev/null 2>&1; then
	stop_disable_units_() {
		unit_pattern=$1
		if ! command -v systemctl >/dev/null 2>&1; then
			return 0
		fi

		while read -r unit_name; do
			if [[ -n "$unit_name" ]]; then
				systemctl disable --now "$unit_name" >/dev/null 2>&1 || true
			fi
		done < <(
			{
				systemctl list-units --all "$unit_pattern" --no-legend --no-pager 2>/dev/null
				systemctl list-unit-files "$unit_pattern" --no-legend --no-pager 2>/dev/null
			} | awk '{print $1}' | sort -u
		)
	}

	reload_systemd_() {
		if command -v systemctl >/dev/null 2>&1; then
			systemctl daemon-reload >/dev/null 2>&1 || true
			systemctl reset-failed >/dev/null 2>&1 || true
		fi
	}

	uninstall_qBittorrent_() {
		info "Uninstalling qBittorrent"
		boring_text "- stopping qbittorrent-nox services"
		stop_disable_units_ "qbittorrent-nox@*.service"
		boring_text "- removing qbittorrent systemd service"
		rm -f /etc/systemd/system/qbittorrent-nox@.service
		boring_text "- removing /usr/bin/qbittorrent-nox"
		rm -f /usr/bin/qbittorrent-nox
		boring_text "- user config and download data kept"
		return 0
	}

	uninstall_autobrr_() {
		info "Uninstalling autobrr"
		boring_text "- stopping autobrr services"
		stop_disable_units_ "autobrr@*.service"
		boring_text "- removing autobrr systemd service"
		rm -f /etc/systemd/system/autobrr@.service
		boring_text "- removing /usr/bin/autobrr"
		rm -f /usr/bin/autobrr
		boring_text "- user config kept"
		return 0
	}

	uninstall_vertex_() {
		info "Uninstalling Vertex"
		if command -v docker >/dev/null 2>&1; then
			if docker ps -a --format '{{.Names}}' | grep -qx "vertex"; then
				boring_text "- removing Docker container vertex"
				docker rm -f vertex >/dev/null 2>&1 || true
			else
				boring_text "- Docker container vertex not found"
			fi
		else
			boring_text "- docker not found, skipping container cleanup"
		fi
		boring_text "- /root/vertex data kept"
		return 0
	}

	uninstall_autoremove-torrents_() {
		info "Uninstalling autoremove-torrents"
		boring_text "- stopping autoremove-torrents services"
		stop_disable_units_ "autoremove-torrents@*.service"
		boring_text "- removing autoremove-torrents systemd service"
		rm -f /etc/systemd/system/autoremove-torrents@.service

		if command -v su >/dev/null 2>&1; then
			for home_dir in /home/*; do
				if [[ -d "$home_dir" ]]; then
					user_name=$(basename "$home_dir")
					boring_text "- uninstalling pipx package for $user_name if present"
					su "$user_name" -s /bin/sh -c "command -v pipx >/dev/null 2>&1 && pipx uninstall autoremove-torrents >/dev/null 2>&1 || true" >/dev/null 2>&1 || true
				fi
			done
		fi
		boring_text "- user config kept"
		return 0
	}

	uninstall_boot_script_() {
		info "Removing boot script"
		boring_text "- stopping boot-script service"
		stop_disable_units_ "boot-script.service"
		boring_text "- removing boot-script service and script"
		rm -f /etc/systemd/system/boot-script.service
		rm -f /root/.boot-script.sh
		return 0
	}

	uninstall_sysctl_tuning_() {
		info "Removing sysctl tuning"
		if [[ -f /etc/sysctl.d/99-seedbox.conf ]]; then
			boring_text "- removing /etc/sysctl.d/99-seedbox.conf"
			rm -f /etc/sysctl.d/99-seedbox.conf
			boring_text "- reloading sysctl settings"
			sysctl --system >/dev/null 2>&1 || true
		else
			boring_text "- seedbox sysctl config not found"
		fi
		return 0
	}

	uninstall_seedbox_() {
		assume_yes=$2

		warn "This will uninstall qBittorrent, autobrr, Vertex, autoremove-torrents, and boot-script."
		warn "User config, download data, system packages, and kernel packages will be kept."

		if [[ "$assume_yes" != "1" ]]; then
			need_input "Continue uninstall? [y/N]"
			read confirm_uninstall
			if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
				warn "Uninstall cancelled"
				return 1
			fi
		fi

		seperator
		uninstall_qBittorrent_
		seperator
		uninstall_autobrr_
		seperator
		uninstall_vertex_
		seperator
		uninstall_autoremove-torrents_
		seperator
		uninstall_boot_script_
		seperator
		uninstall_sysctl_tuning_
		reload_systemd_

		info "Seedbox uninstall complete"
		boring_text "User config and data were kept."
		return 0
	}
fi

## Main menu
show_main_menu() {
	info "Seedbox"
	need_input "1. 一键安装 / One-click Install"
	need_input "2. 一键卸载 / One-click Uninstall"
	need_input "3. Help"
	need_input "0. Exit"
	need_input "Please choose an option:"
	read menu_choice
	case "$menu_choice" in
		1 )
			menu_install=1
			;;
		2 )
			menu_uninstall=1
			;;
		3 )
			menu_help=1
			;;
		0 )
			exit 0
			;;
		* )
			fail_exit "Invalid option"
			;;
	esac
}

## Install function
start_progress_() {
	progress_message=$1
	(
		i=0
		while true; do
			case $((i % 4)) in
				0) dots="" ;;
				1) dots="." ;;
				2) dots=".." ;;
				3) dots="..." ;;
			esac
			printf "\r\t%s%s" "$progress_message" "$dots"
			i=$((i + 1))
			sleep 1
		done
	) &
	progress_pid=$!
}

stop_progress_() {
	if [[ -n "$progress_pid" ]]; then
		kill "$progress_pid" >/dev/null 2>&1 || true
		wait "$progress_pid" 2>/dev/null || true
		progress_pid=""
	fi
}

install_() {
info_2 "$2"
error_log=$3
: > "$error_log"
start_progress_ "$2"
$1 1> /dev/null 2> "$error_log"
status=$?
stop_progress_
if [ $status -eq 2 ]; then
	printf "\r\e[K"
	warn "$2: SKIP"
	if [ -s "$error_log" ]; then
		warn "Reason:"
		tail -n 20 "$error_log" >&2
	fi
elif [ $status -ne 0 ]; then
	printf "\r\e[K"
	fail_3 "$2: FAIL"
	echo
	if [ -s "$error_log" ]; then
		warn "Last error output:"
		tail -n 20 "$error_log" >&2
	else
		warn "No error output was captured. Check the command manually."
	fi
else
	printf "\r\e[K"
	info_3 "$2: Successful"
	export $4=1
fi
echo
}

optional_install_() {
	info_2 "$2"
	error_log=$3
	: > "$error_log"
	start_progress_ "$2"
	$1 1> /dev/null 2> "$error_log"
	status=$?
	stop_progress_
	if [ $status -ne 0 ]; then
		printf "\r\e[K"
		warn "$2: SKIP"
		if [ -s "$error_log" ]; then
			warn "Reason:"
			tail -n 10 "$error_log" >&2
		fi
	else
		printf "\r\e[K"
		info_3 "$2: Successful"
		export $4=1
	fi
	echo
}

## Installation environment Check
info "Checking Installation Environment"
# Check Root Privilege
if [ $(id -u) -ne 0 ]; then 
    fail_exit "This script needs root permission to run"
fi

# Linux Distro Version check
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	OS=Debian
	VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
	OS=SuSe
elif [ -f /etc/redhat-release ]; then
	OS=Redhat
else
	OS=$(uname -s)
	VER=$(uname -r)
fi

if [[ ! "$OS" =~ "Debian" ]] && [[ ! "$OS" =~ "Ubuntu" ]]; then	#Only Debian and Ubuntu are supported
	fail "$OS $VER is not supported"
	info "Only Debian 10+ and Ubuntu 20.04+ are supported"
	exit 1
fi

if [[ "$OS" =~ "Debian" ]]; then	#Debian 10+ are supported
	if [[ ! "$VER" =~ "10" ]] && [[ ! "$VER" =~ "11" ]] && [[ ! "$VER" =~ "12" ]] && [[ ! "$VER" =~ "13" ]]; then
		fail "$OS $VER is not supported"
		info "Only Debian 10, 11, 12, and 13 are supported"
		exit 1
	fi
fi

if [[ "$OS" =~ "Ubuntu" ]]; then #Ubuntu 20.04+ are supported
	if [[ ! "$VER" =~ "20" ]] && [[ ! "$VER" =~ "22" ]] && [[ ! "$VER" =~ "23" ]]; then
		fail "$OS $VER is not supported"
		info "Only Ubuntu 20.04+ is supported"
		exit 1
	fi
fi

if [ $# -eq 0 ]; then
	show_main_menu
fi

normalized_args=()
while [ $# -gt 0 ]; do
	case "$1" in
		--install )
			menu_install=1
			;;
		--uninstall )
			normalized_args+=("-U")
			;;
		--yes )
			normalized_args+=("-y")
			;;
		* )
			normalized_args+=("$1")
			;;
	esac
	shift
done
if [[ -n "$menu_uninstall" ]]; then
	normalized_args+=("-U")
fi
if [[ -n "$menu_help" ]]; then
	normalized_args+=("-h")
fi
set -- "${normalized_args[@]}"

## Read input arguments
while getopts "u:p:c:q:l:rvoUhy" opt; do
  case ${opt} in
	u ) # process option username
		username=${OPTARG}
		;;
	p ) # process option password
		password=${OPTARG}
		;;
	c ) # process option cache
		cache=${OPTARG}
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		#Converting the cache to qBittorrent's unit (MiB)
		qb_cache=$cache
		;;
	q ) # process option cache
		qb_install=1
		qb_ver=("qBittorrent-${OPTARG}")
		;;
	l ) # process option libtorrent
		lib_ver=("libtorrent-${OPTARG}")
		#Check if qBittorrent version is specified
		if [ -z "$qb_ver" ]; then
			warn "You must choose a qBittorrent version for your libtorrent install"
			qb_ver_choose
		fi
		;;
	r ) # process option autoremove
		autoremove_install=1
		;;
	v ) # process option vertex
		vertex_install=1
		;;
	U ) # process option uninstall
		uninstall_mode=1
		;;
	y ) # process option assume yes
		assume_yes=1
		;;
	o ) # process option port
		if [[ -n "$qb_install" ]]; then
			need_input "Please enter qBittorrent port:"
			read qb_port
			while true
			do
				if ! [[ "$qb_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter qBittorrent port:"
					read qb_port
				else
					break
				fi
			done
			need_input "Please enter qBittorrent incoming port:"
			read qb_incoming_port
			while true
			do
				if ! [[ "$qb_incoming_port" =~ ^[0-9]+$ ]]; then
						warn "Port must be a number"
						need_input "Please enter qBittorrent incoming port:"
						read qb_incoming_port
				else
					break
				fi
			done
		fi
		if [[ -n "$vertex_install" ]]; then
			need_input "Please enter vertex port:"
			read vertex_port
			while true
			do
				if ! [[ "$vertex_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter vertex port:"
					read vertex_port
				else
					break
				fi
			done
		fi
		;;
	h ) # process option help
		info "Help:"
		info "Usage: ./install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -v -r -o"
		info "Uninstall: ./install.sh -U"
		info "Example: ./install.sh -u admin -p adminadmin -c 4096 -q 4.3.9 -l v1.2.15 -v -r"
		source <(curl -fsSL "$QB_INSTALL_URL")
		seperator
		info "Options:"
		need_input "1. -u : Username"
		need_input "2. -p : Password"
		need_input "3. -c : Cache Size for qBittorrent (unit:MiB)"
		echo -e "\n"
		need_input "4. -q : qBittorrent version"
		need_input "Available qBittorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${qb_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "5. -l : libtorrent version"
		need_input "Available libtorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${lib_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "6. -r : Install autoremove-torrents"
		need_input "7. -v : Install vertex"
		need_input "8. -o : Specify ports for qBittorrent and vertex"
		need_input "9. -U : One-click uninstall"
		need_input "10. -y : Assume yes when uninstalling"
		need_input "11. -h : Display help message"
		exit 0
		;;
	\? ) 
		info "Help:"
		info_2 "Usage: ./install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -v -r -o"
		info_2 "Example ./install.sh -u jerry048 -p 1LDw39VOgors -c 3072 -q 4.3.9 -l v1.2.19 -v -r"
		exit 1
		;;
	esac
done

if [[ -n "$menu_install" ]]; then
	qb_install=1
	autoremove_install=1
	vertex_install=1
fi

if [[ -n "$uninstall_mode" ]]; then
	info "Start Seedbox Uninstall"
	uninstall_seedbox_ "$username" "$assume_yes"
	exit $?
fi

# System Update & Dependencies Install
info "Start System Update & Dependencies Install"
update

## Install Seedbox Environment
tput sgr0; clear
info "Start Installing Seedbox Environment"
echo -e "\n"


# qBittorrent
source <(curl -fsSL "$QB_INSTALL_URL")
# Check if qBittorrent install is successfully loaded
if [ $? -ne 0 ]; then
	fail_exit "Component ~qBittorrent install~ failed to load"
fi

if [[ ! -z "$qb_install" ]]; then
	## Check if all the required arguments are specified
	#Check if username is specified
	if [ -z "$username" ]; then
		warn "Username is not specified"
		need_input "Please enter a username:"
		read username
	fi
	#Check if password is specified
	if [ -z "$password" ]; then
		warn "Password is not specified"
		need_input "Please enter a password:"
		read password
	fi
	## Create user if it does not exist
	if ! id -u $username > /dev/null 2>&1; then
		useradd -m -s /bin/bash $username
		# Check if the user is created successfully
		if [ $? -ne 0 ]; then
			warn "Failed to create user $username"
			return 1
		fi
	fi
	chown -R $username:$username /home/$username
	#Check if cache is specified
	if [ -z "$cache" ]; then
		warn "Cache is not specified"
		need_input "Please enter a cache size (in MB):"
		read cache
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		qb_cache=$cache
	fi
	#Check if qBittorrent version is specified
	if [ -z "$qb_ver" ]; then
		warn "qBittorrent version is not specified"
		qb_ver_check
	fi
	#Check if libtorrent version is specified
	if [ -z "$lib_ver" ]; then
		warn "libtorrent version is not specified"
		lib_ver_check
	fi
	#Check if qBittorrent port is specified
	if [ -z "$qb_port" ]; then
		qb_port=8080
	fi
	#Check if qBittorrent incoming port is specified
	if [ -z "$qb_incoming_port" ]; then
		qb_incoming_port=45000
	fi

	## qBittorrent & libtorrent compatibility check
	qb_install_check

	## qBittorrent install
	install_ "install_qBittorrent_ $username $password $qb_ver $lib_ver $qb_cache $qb_port $qb_incoming_port" "Installing qBittorrent" "/tmp/qb_error" qb_install_success
fi

# vertex Install
if [[ ! -z "$vertex_install" ]]; then
	install_ install_vertex_ "Installing vertex" "/tmp/vertex_error" vertex_install_success
fi

# autoremove-torrents Install
if [[ ! -z "$autoremove_install" ]]; then
	install_ install_autoremove-torrents_ "Installing autoremove-torrents" "/tmp/autoremove_error" autoremove_install_success
fi

seperator

## Tunning
info "Start Doing System Tunning"
optional_install_ tuned_ "Installing tuned" "/tmp/tuned_error" tuned_success
optional_install_ set_txqueuelen_ "Setting txqueuelen" "/tmp/txqueuelen_error" txqueuelen_success
optional_install_ set_file_open_limit_ "Setting File Open Limit" "/tmp/file_open_limit_error" file_open_limit_success

# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
	warn "Virtualization is detected, skipping some of the tunning"
	optional_install_ disable_tso_ "Disabling TSO" "/tmp/tso_error" tso_success
else
	optional_install_ set_disk_scheduler_ "Setting Disk Scheduler" "/tmp/disk_scheduler_error" disk_scheduler_success
	optional_install_ set_ring_buffer_ "Setting Ring Buffer" "/tmp/ring_buffer_error" ring_buffer_success
fi
optional_install_ set_initial_congestion_window_ "Setting Initial Congestion Window" "/tmp/initial_congestion_window_error" initial_congestion_window_success
optional_install_ kernel_settings_ "Setting Kernel Settings" "/tmp/kernel_settings_error" kernel_settings_success



## Configue Boot Script
info "Start Configuing Boot Script"
touch /root/.boot-script.sh && chmod +x /root/.boot-script.sh
cat << EOF > /root/.boot-script.sh
#!/bin/bash
sleep 120s
source <(curl -fsSL "$SEEDBOX_INSTALLATION_URL")
# Check if Seedbox Components is successfully loaded
if [ \$? -ne 0 ]; then
	exit 1
fi
set_txqueuelen_
# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ \$? -eq 0 ]; then
	disable_tso_
else
	set_disk_scheduler_
	set_ring_buffer_
fi
set_initial_congestion_window_
EOF
# Configure the script to run during system startup
cat << EOF > /etc/systemd/system/boot-script.service
[Unit]
Description=boot-script
After=network.target

[Service]
Type=simple
ExecStart=/root/.boot-script.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable boot-script.service


seperator

## Finalizing the install
info "Seedbox Installation Complete"
publicip=$(curl -s https://ipinfo.io/ip)

# Display Username and Password
# qBittorrent
if [[ ! -z "$qb_install_success" ]]; then
	info "qBittorrent installed"
	boring_text "qBittorrent WebUI: http://$publicip:$qb_port"
	boring_text "qBittorrent Username: $username"
	boring_text "qBittorrent Password: $password"
	echo -e "\n"
fi
# autoremove-torrents
if [[ ! -z "$autoremove_install_success" ]]; then
	info "autoremove-torrents installed"
	boring_text "Config at /home/$username/.config.yml"
	boring_text "Please read https://autoremove-torrents.readthedocs.io/en/latest/config.html for configuration"
	echo -e "\n"
fi
# vertex
if [[ ! -z "$vertex_install_success" ]]; then
	info "vertex installed"
	boring_text "vertex WebUI: http://$publicip:$vertex_port"
	boring_text "vertex Username: $username"
	boring_text "vertex Password: $password"
	echo -e "\n"
fi
exit 0
