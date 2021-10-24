#!/bin/bash
# Default variables
type="install"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs an Evmos node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help    show the help page"
		echo -e "  -u, --update  update the node"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Evmos/blob/main/multi_tool.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-u|--update)
		type="update"
		shift
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
install() {
	sudo apt update
	sudo apt upgrade -y
	sudo apt install wget git build-essential make jq -y
	mkdir $HOME/evmos_temp
	evmos_version=`wget -qO- https://api.github.com/repos/tharsis/evmos/releases/latest | jq -r ".tag_name" | sed "s%v%%g"`
	wget -q "https://github.com/tharsis/evmos/releases/download/v${evmos_version}/evmos_${evmos_version}_Linux_x86_64.tar.gz"
	tar -xvf "evmos_${evmos_version}_Linux_x86_64.tar.gz" -C $HOME/evmos_temp
	mv $HOME/evmos_temp/bin/evmosd /usr/bin/evmosd
	rm -rf $HOME/evmos_temp "evmos_${evmos_version}_Linux_x86_64.tar.gz"
	evmosd version
	printf "[Unit]
Description=Evmos Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=`which evmosd` start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/evmosd.service
	sudo systemctl daemon-reload
	sudo systemctl enable evmosd
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n evmos_log -v "sudo journalctl -f -n 100 -u evmosd" -a
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n evmos_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/SecorD0/Evmos/main/node_info.sh) -l RU 2> /dev/null" -a
}
# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)

if [ "$type" = "update" ]; then
	sudo systemctl stop evmosd
	rm -rf `which evmosd`
	install
	sudo systemctl restart evmosd
else
	install
fi
printf_n "${C_LGn}Done!${RES}"
