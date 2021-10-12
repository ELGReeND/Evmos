#!/bin/bash
# Default variables
daemon="`which evmosd`"
config_dir="$HOME/.evmosd/"
language="EN"
raw_output="false"
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about a Umee node"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help               show help page"
		echo -e "  -l, --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                           LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -ro, --raw-output        the raw JSON output"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Umee/blob/main/node_info.sh - script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
# Texts
if [ "$language" = "RU" ]; then
	t_nn="\nНазвание ноды:                ${C_LGn}%s${RES}"
	t_id="Keybase ключ:                 ${C_LGn}%s${RES}"
	t_si="Сайт:                         ${C_LGn}%s${RES}"
	t_det="Описание:                     ${C_LGn}%s${RES}"
	t_net="Сеть:                         ${C_LGn}%s${RES}"
	t_ver="Версия ноды:                  ${C_LGn}%s${RES}\n"
	t_pk="Публичный ключ валидатора:    ${C_LGn}%s${RES}"
	t_va="Адрес валидатора:             ${C_LGn}%s${RES}"
	t_nij1="Нода в тюрьме:                ${C_LR}да${RES}"
	t_nij2="Нода в тюрьме:                ${C_LGn}нет${RES}"
	t_lb="Последний блок:               ${C_LGn}%s${RES}"
	t_sy1="Нода синхронизирована:        ${C_LR}нет${RES}"
	t_sy2="Осталось нагнать:             ${C_LR}%d-%d=%d (около %.2f мин.)${RES}"
	t_sy3="Нода синхронизирована:        ${C_LGn}да${RES}"
	t_del="Делегировано токенов на ноду: ${C_LGn}%.3f${RES}"
	t_vp="Весомость голоса:             ${C_LGn}%s${RES}\n"
# Send Pull request with new texts to add a language - https://github.com/SecorD0/KiChain/blob/main/node_info.sh
#elif [ "$language" = ".." ]; then
else
	t_nn="\nMoniker:                       ${C_LGn}%s${RES}"
	t_id="Keybase key:                   ${C_LGn}%s${RES}"
	t_si="Website:                       ${C_LGn}%s${RES}"
	t_det="Details:                       ${C_LGn}%s${RES}"
	t_net="Network:                       ${C_LGn}%s${RES}"
	t_ver="Node version:                  ${C_LGn}%s${RES}\n"
	t_pk="Validator public key:          ${C_LGn}%s${RES}"
	t_va="Validator address:             ${C_LGn}%s${RES}"
	t_nij1="The node in a jail:            ${C_LR}yes${RES}"
	t_nij2="The node in a jail:            ${C_LGn}no${RES}"
	t_lb="Latest block height:           ${C_LGn}%s${RES}"
	t_sy1="The node is synchronized:      ${C_LR}no${RES}"
	t_sy2="It remains to catch up:        ${C_LR}%d-%d=%d (about %.2f min.)${RES}"
	t_sy3="The node is synchronized:      ${C_LGn}yes${RES}"
	t_del="Delegated tokens to the node:  ${C_LGn}%.3f${RES}"
	t_vp="Voting power:                  ${C_LGn}%s${RES}\n"
fi
# Actions
sudo apt install bc -y &>/dev/null
node_tcp=`cat "${config_dir}config/config.toml" | grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")"`
status=`$daemon status --node "$node_tcp" 2>&1`
moniker=`jq -r ".NodeInfo.moniker" <<< $status`
node_info=`$daemon query staking validators --node "$node_tcp" --limit 1500 --output json | jq -r '.validators[] | select(.description.moniker=='\"$moniker\"')'`
identity=`jq -r ".description.identity" <<< $node_info`
website=`jq -r ".description.website" <<< $node_info`
details=`jq -r ".description.details" <<< $node_info`
network=`jq -r ".NodeInfo.network" <<< $status`
version=`jq -r ".NodeInfo.version" <<< $status`
validator_pub_key=`$daemon tendermint show-validator`
validator_address=`jq -r ".operator_address" <<< $node_info`
jailed=`jq -r ".jailed" <<< $node_info`
latest_block_height=`jq -r ".SyncInfo.latest_block_height" <<< $status`
catching_up=`jq -r ".SyncInfo.catching_up" <<< $status`
delegated=`bc -l <<< "$(jq -r ".tokens" <<< $node_info)/1000000"`
voting_power=`jq -r ".ValidatorInfo.VotingPower" <<< $status`
# Output
if [ "$raw_output" = "true" ]; then
	printf_n '{"moniker": "%s", "identity": "%s", "website": "%s", "details": "%s", "network": "%s", "version": "%s", "validator_pub_key": "%s", "validator_address": "%s", "jailed": %b, "latest_block_height": %d, "catching_up": %b, "delegated": %.3f, "voting_power": %d}' \
"$moniker" \
"$identity" \
"$website" \
"$details" \
"$network" \
"$version" \
"$validator_pub_key" \
"$validator_address" \
"$jailed" \
"$latest_block_height" \
"$catching_up" \
"$delegated" \
"$voting_power"
else
	printf_n "$t_nn" "$moniker"
	printf_n "$t_id" "$identity"
	printf_n "$t_si" "$website"
	printf_n "$t_det" "$details"
	printf_n "$t_net" "$network"
	printf_n "$t_ver" "$version"
	printf_n "$t_pk" "$validator_pub_key"
	printf_n "$t_va" "$validator_address"
	if [ "$jailed" = "true" ]; then
		printf_n "$t_nij1"
	else
		printf_n "$t_nij2"
	fi
	printf_n "$t_lb" "$latest_block_height"
	if [ "$catching_up" = "true" ]; then
		current_block=`wget -qO- 5.189.156.65:26657/block | jq -r ".result.block.header.height"`
		diff=`bc -l <<< "$current_block-$latest_block_height"`
		takes_time=`bc -l <<< "$diff/53/60"`
		printf_n "$t_sy1"
		printf_n "$t_sy2" "$current_block" "$latest_block_height" "$diff" "$takes_time"		
	else
		printf_n "$t_sy3"
	fi
	printf_n "$t_del" "$delegated"
	printf_n "$t_vp" "$voting_power"
fi
