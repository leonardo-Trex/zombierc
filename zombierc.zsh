#!/usr/bin/env zsh
# =============================================================================
# zombierc.zsh - Micro gerenciador e compilador de plugins para Zsh
#
# Filosofia: KISS (Keep It Simple, Stupid), defensivo, rápido e linear.
# =============================================================================

# 1. Configurações de modo estrito (defensivo)
setopt ERR_EXIT NO_UNSET PIPE_FAIL

# 2. Validações preliminares do ambiente
if [[ -z "${ZSH_VERSION:-}" ]]; then
  print -u2 "[ ERRO ] Este instalador requer o interpretador Zsh."
  exit 1
fi

if (( EUID == 0 )); then
  print -P "%F{red}%B[ ERRO ]%b Não execute este instalador com privilégios de root ou sudo.%f" >&2
  exit 1
fi

# 3. Verificação de ferramentas necessárias e opcionais
typeset -a required_deps=(git curl)
for dep in "${required_deps[@]}"; do
  if (( ! $+commands[$dep] )); then
    print -P "%F{red}%B[ ERRO ]%b Dependência obrigatória ausente: %F{yellow}${dep}%f" >&2
    exit 1
  fi
done

typeset -a optional_deps=(bat eza)
for dep in "${optional_deps[@]}"; do
  if (( ! $+commands[$dep] )); then
    print -P "%F{yellow}%B[ AVISO ]%b Ferramenta opcional recomendada não encontrada: %F{cyan}${dep}%f"
  fi
done

# 4. Diretórios base (respeitando a especificação XDG Base Directory)
typeset xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
typeset xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"

typeset plugins_dir="${xdg_data}/zsh/plugins"
typeset cache_dir="${xdg_cache}/zsh"
typeset bundle_file="${cache_dir}/bundle.zsh"

mkdir -p "$plugins_dir" "$cache_dir"

# 5. Lista de plugins na ordem ideal de carregamento
typeset -a bundle_plugins=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-history-substring-search"
  "https://github.com/zdharma-continuum/fast-syntax-highlighting"
)

# 6. Sincronização / Download dos repositórios via Git
print -P "\n%F{blue}%B[ 1/3 ]%b Sincronizando plugins...%f"
for url in "${bundle_plugins[@]}"; do
  typeset plugin_name="${url:t}"
  typeset dest="${plugins_dir}/${plugin_name}"

  if [[ -d "$dest" ]]; then
    print -P "  %F{green}✓%f %F{cyan}${plugin_name}%f já instalado."
  else
    print -P "  %F{yellow}↓%f Clonando %F{cyan}${plugin_name}%f..."
    git clone --depth 1 --quiet "$url" "$dest"
    print -P "  %F{green}✓%f %F{cyan}${plugin_name}%f instalado com sucesso."
  fi
done

# 7. Geração do Bundle consolidado
print -P "\n%F{blue}%B[ 2/3 ]%b Consolidando plugins no bundle...%f"
cat << 'EOF' > "$bundle_file"
# =============================================================================
# ZOMBIERC - Bundle de Plugins ZSH consolidado
# Gerado automaticamente por zombierc.zsh. Não edite manualmente.
# =============================================================================
EOF

for url in "${bundle_plugins[@]}"; do
  typeset plugin_name="${url:t}"
  typeset dest="${plugins_dir}/${plugin_name}"
  typeset entry=""

  # Localiza o arquivo principal de entrada do plugin
  if [[ -f "${dest}/${plugin_name}.zsh" ]]; then
    entry="${dest}/${plugin_name}.zsh"
  elif [[ -f "${dest}/${plugin_name}.plugin.zsh" ]]; then
    entry="${dest}/${plugin_name}.plugin.zsh"
  elif [[ -f "${dest}/${plugin_name}.sh" ]]; then
    entry="${dest}/${plugin_name}.sh"
  fi

  if [[ -z "$entry" ]]; then
    print -P "  %F{red}%B[ ERRO ]%b Ponto de entrada não encontrado para: %F{yellow}${plugin_name}%f" >&2
    exit 1
  fi

  print -P "  %F{green}+%f Empacotando %F{cyan}${plugin_name}%f (%F{yellow}${entry:t}%f)"

  # Incorpora o código no bundle definindo ZERO conforme o Zsh Plugin Standard
  {
    print "\n# --- [ Plugin: ${plugin_name} ] ---"
    print "ZERO=\"${entry}\""
    cat "$entry"
  } >> "$bundle_file"
done

# 8. Compilação para Zsh Word Code (.zwc)
print -P "\n%F{blue}%B[ 3/3 ]%b Compilando bundle com zcompile...%f"
rm -f "${bundle_file}.zwc"
zcompile -R "$bundle_file"
print -P "  %F{green}✓%f Arquivo compilado gerado: %F{cyan}${bundle_file}.zwc%f"

# 9. Verificação amigável de shell padrão (sem sudo / intrusão)
if [[ "${SHELL:t}" != "zsh" ]]; then
  print -P "\n%F{yellow}%B[ AVISO ]%b O Zsh não está definido como seu shell padrão (atual: %F{cyan}${SHELL:t}%f)."
  print -P "Você pode alterar o shell padrão do seu usuário com:"
  print -P "  %F{green}chsh -s ${(q)commands[zsh]}%f"
  print -P "A mudança vai se refletir quando a sessão for reiniciada."
fi

# 10. Instruções finais
print -P "\n%F{green}%B✨ Configuração concluída com sucesso!%b%f"
print -P "Para carregar o bundle compilado no seu %F{yellow}~/.zshrc%f:"
print -P "  %F{cyan}[[ -f \"${bundle_file}\" ]] && source \"${bundle_file}\"%f\n"
