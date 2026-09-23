#!/usr/bin/env zsh

setopt errexit nounset pipefail err_return

if [[ -z "${ZSH_VERSION:-}" ]]; then
	echo "%F{red}[ ERROR ]%f - preciso do zsh"
	exit 1
fi

if (( EUID == 0 )); then
	print -P "%F{red}[ ERROR ]%f - Sem root "
	exit 1
fi


local -a deps=(git curl oxyde)
for dep in "${deps[@]}"; do
	if ! command -v "$dep" &>/dev/null; then 
		print -P "%F{red}Faltou%f o %F{yellow}$dep%f"
		exit 1
	fi	
done
#-------------------------------------------------------------------------



