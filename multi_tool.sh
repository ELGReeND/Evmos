#!/bin/bash
# Default variables
function="install"

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
		function="update"
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
	local evmos_version=`wget -qO- https://api.github.com/repos/tharsis/evmos/releases/latest | jq -r ".tag_name" | sed "s%v%%g"`
	wget -q "https://github.com/tharsis/evmos/releases/download/v${evmos_version}/evmos_${evmos_version}_Linux_x86_64.tar.gz"
	tar -xvf "evmos_${evmos_version}_Linux_x86_64.tar.gz" -C $HOME/evmos_temp
	mv $HOME/evmos_temp/bin/evmosd /usr/bin
	rm -rf $HOME/evmos_temp "evmos_${evmos_version}_Linux_x86_64.tar.gz"
}
update() {
	sudo systemctl stop evmosd
	mkdir $HOME/evmos_temp
	local evmos_version=`wget -qO- https://api.github.com/repos/tharsis/evmos/releases/latest | jq -r ".tag_name" | sed "s%v%%g"`
	wget -q "https://github.com/tharsis/evmos/releases/download/v${evmos_version}/evmos_${evmos_version}_Linux_x86_64.tar.gz"
	tar -xvf "evmos_${evmos_version}_Linux_x86_64.tar.gz" -C $HOME/evmos_temp
	mv $HOME/evmos_temp/bin/evmosd /usr/bin
	rm -rf $HOME/evmos_temp "evmos_${evmos_version}_Linux_x86_64.tar.gz"
}

# Actions
sudo apt install wget -y
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
$function
printf_n "${C_LGn}Done!${RES}"
