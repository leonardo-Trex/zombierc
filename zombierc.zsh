#!/usr/bin/env zsh

setopt errexit nounset pipefail err_return

if [[ -z "${ZSH_VERSION:-}" ]]; then
	echo "%F{red}[ ERRO ]%f - preciso do zsh"
	exit 1
fi

if (( EUID == 0 )); then
	print -P "%F{red}[ ERRO ]%f - Sem root "
	exit 1
fi


local -a deps=(git curl)
for dep in "${deps[@]}"; do
	if ! command -v "$dep" &>/dev/null; then 
		print -P "%F{red}[ ERRO ]%f faltou o %F{yellow}$dep%f"
		exit 1
	fi	
done
#-------------------------------------------------------------------------
typeset xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
typeset plugins_dir="${xdg_data}/zsh/plugins"

mkdir -p "$plugins_dir"

local -a plugins_url=(
		"https://github.com/zsh-users/zsh-autosuggestions"
		"https://github.com/zsh-users/zsh-syntax-highlighting"
	)

for url in "${plugins_url[@]}"; do
	plugin_name="${url:t}"
	dest="${plugins_dir}/${plugin_name}"
	
	if [[ -d "$dest" ]]; then
		echo "já tá instalado"
	else
		echo "instalando"
		git clone --depth 1 "$url" "$dest"
	fi

done


#-------------------------------------------------------------------------


