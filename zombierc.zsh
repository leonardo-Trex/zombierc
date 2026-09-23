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
typeset xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

typeset plugins_dir="${xdg_data}/zsh/plugins"
typeset cache_dir="${xdg_cache}/zsh"
typeset config_dir="${xdg_config}/zsh"
typeset bundle_file="${cache_dir}/bundle.zsh"
typeset zshrc_file="$HOME/.zshrc"
typeset aliases_file="${config_dir}/aliases.zsh"

mkdir -p "$plugins_dir" "$cache_dir" "$config_dir"

# 5. Lista de plugins na ordem ideal de carregamento
typeset -a bundle_plugins=(
  "https://github.com/mattmc3/ez-compinit"
  "https://github.com/zsh-users/zsh-completions"
  "https://github.com/sindresorhus/pure"
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zdharma-continuum/fast-syntax-highlighting"
  "https://github.com/zsh-users/zsh-history-substring-search"
)

# 6. Sincronização / Download dos repositórios via Git
print -P "\n%F{blue}%B[ 1/4 ]%b Sincronizando plugins...%f"
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
print -P "\n%F{blue}%B[ 2/4 ]%b Consolidando plugins no bundle...%f"

# 7.1 Mapeamento defensivo dos diretórios de funções e completações (fpath)
# Garante que qualquer diretório com scripts de completion (_*), prompts ou autoload
# seja registrado no fpath antes que compinit ou os plugins sejam executados.
typeset -a fpath_dirs=()

for url in "${bundle_plugins[@]}"; do
  typeset plugin_name="${url:t}"
  typeset dest="${plugins_dir}/${plugin_name}"

  # Subdiretório src/ com arquivos de completion (_*) - ex: zsh-completions
  if [[ -d "${dest}/src" ]] && () { local -a f; f=("${dest}/src"/_*(N)); (( $#f > 0 )); }; then
    fpath_dirs+=("${dest}/src")
  fi

  # Subdiretório functions/ com funções autoloadáveis - ex: ez-compinit
  if [[ -d "${dest}/functions" ]]; then
    fpath_dirs+=("${dest}/functions")
  fi

  # Diretório raiz com arquivos de completion (_*) ou temas de prompt (prompt_*_setup) - ex: pure, fast-syntax-highlighting
  if () { local -a f; f=("${dest}"/(_*|prompt_*_setup)(N)); (( $#f > 0 )); }; then
    fpath_dirs+=("${dest}")
  fi
done

# 7.2 Criação do cabeçalho e injeção do fpath no bundle
cat << 'EOF' > "$bundle_file"
# =============================================================================
# ZOMBIERC - Bundle de Plugins ZSH consolidado
# Gerado automaticamente por zombierc.zsh. Não edite manualmente.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Configuração do fpath (completions e autoloads)
# -----------------------------------------------------------------------------
typeset -gU fpath FPATH
fpath=(
EOF

for dir in "${fpath_dirs[@]}"; do
  print "  \"${dir}\"" >> "$bundle_file"
done

cat << 'EOF' >> "$bundle_file"
  $fpath
)

# -----------------------------------------------------------------------------
# 2. Carregamento dos Plugins
# -----------------------------------------------------------------------------
EOF

# 7.3 Processamento e integração dos plugins
for url in "${bundle_plugins[@]}"; do
  typeset plugin_name="${url:t}"
  typeset dest="${plugins_dir}/${plugin_name}"

  case "$plugin_name" in
    zsh-completions)
      # Repositório puro de completações: seus scripts vivem em src/ e já foram
      # adicionados ao fpath acima. Dispensado de source ou concatenação inline.
      print -P "  %F{green}+%f Registrando %F{cyan}${plugin_name}%f (%F{yellow}completions em fpath%f)"
      {
        print "\n# --- [ Plugin: ${plugin_name} ] ---"
        print "# Completions registradas no fpath (${dest}/src)."
      } >> "$bundle_file"
      ;;

    pure)
      # Prompt Pure: integrado via promptinit oficial do Zsh
      print -P "  %F{green}+%f Integrando prompt %F{cyan}${plugin_name}%f (%F{yellow}promptinit + prompt pure%f)"
      {
        print "\n# --- [ Prompt: ${plugin_name} ] ---"
        print "autoload -Uz promptinit && promptinit"
        print "prompt pure"
      } >> "$bundle_file"

      # Compilação dos arquivos de funções do pure e async para bytecode
      [[ -f "${dest}/async" ]] && zcompile -R "${dest}/async"
      [[ -f "${dest}/prompt_pure_setup" ]] && zcompile -R "${dest}/prompt_pure_setup"
      ;;

    ez-compinit)
      # Gerenciador de compinit: requer source isolado para manter integridade do
      # $0 (${0:a:h}/functions), compdef queue, hooks e guarda de terminal ($TERM != dumb).
      typeset entry="${dest}/${plugin_name}.plugin.zsh"
      if [[ ! -f "$entry" ]]; then
        print -P "  %F{red}%B[ ERRO ]%b Ponto de entrada não encontrado para: %F{yellow}${plugin_name}%f" >&2
        exit 1
      fi

      print -P "  %F{green}+%f Integrando %F{cyan}${plugin_name}%f (%F{yellow}source isolado com zcompile%f)"
      {
        print "\n# --- [ Plugin: ${plugin_name} ] ---"
        print "[[ -f \"${entry}\" ]] && source \"${entry}\" || true"
      } >> "$bundle_file"

      # Pré-compilação do script do ez-compinit para bytecode
      zcompile -R "$entry"
      ;;

    *)
      # Plugins de scripts convencionais: localiza o entrypoint e consolida no bundle
      typeset entry=""
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
      ;;
  esac
done

# 8. Compilação para Zsh Word Code (.zwc)
print -P "\n%F{blue}%B[ 3/4 ]%b Compilando bundle e limpando cache antigo...%f"
rm -rf "${bundle_file}.zwc" "${cache_dir}"/zcompdump*(N)
zcompile -R "$bundle_file"
print -P "  %F{green}✓%f Arquivo compilado gerado: %F{cyan}${bundle_file}.zwc%f"
if [[ -f "${plugins_dir}/ez-compinit/ez-compinit.plugin.zsh.zwc" ]]; then
  print -P "  %F{green}✓%f Bytecode ez-compinit gerado: %F{cyan}ez-compinit.plugin.zsh.zwc%f"
fi
if [[ -f "${plugins_dir}/pure/prompt_pure_setup.zwc" ]]; then
  print -P "  %F{green}✓%f Bytecode pure prompt gerado: %F{cyan}prompt_pure_setup.zwc%f"
fi

# 9. Configuração do ~/.zshrc e aliases.zsh
print -P "\n%F{blue}%B[ 4/4 ]%b Configurando ~/.zshrc e aliases...%f"

# 9.1 Criação do arquivo de aliases inicial se não existir
if [[ ! -f "$aliases_file" ]]; then
  cat << 'EOF' > "$aliases_file"
# =============================================================================
# ~/.config/zsh/aliases.zsh - Atalhos e aliases do usuário
# =============================================================================

# Listagem inteligente (usando eza se disponível)
if (( $+commands[eza] )); then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -la --icons --group-directories-first --git"
  alias lt="eza --tree --level=2 --icons"
else
  alias ls="ls --color=auto"
  alias ll="ls -la"
fi

# Visualizador avançado de texto (usando bat se disponível)
if (( $+commands[bat] )); then
  alias cat="bat --paging=never"
fi

# Navegação e comandos frequentes
alias ..="cd .."
alias ...="cd ../.."
alias g="git"
EOF
  print -P "  %F{green}✓%f Arquivo inicial de aliases criado: %F{cyan}${aliases_file}%f"
else
  print -P "  %F{green}✓%f Arquivo de aliases existente preservado: %F{cyan}${aliases_file}%f"
fi

# Compilação dos aliases para .zwc
zcompile -R "$aliases_file"

# 9.2 Configuração idempotente do ~/.zshrc
typeset bundle_line="[[ -f \"${bundle_file}\" ]] && source \"${bundle_file}\""
typeset aliases_line="[[ -f \"${aliases_file}\" ]] && source \"${aliases_file}\""

if [[ ! -f "$zshrc_file" ]]; then
  cat << EOF > "$zshrc_file"
# =============================================================================
# ~/.zshrc - Configuração do Zsh gerenciada pelo Zombierc
# =============================================================================

# Cache inteligente do compinit (20h) para inicialização instantânea
zstyle ':plugin:ez-compinit' 'use-cache' 'yes'

# Carregamento do bundle consolidado e compilado (.zwc)
${bundle_line}

# Carregamento de aliases do usuário
${aliases_line}
EOF
  print -P "  %F{green}✓%f Arquivo %F{cyan}~/.zshrc%f criado e configurado."
else
  typeset -i updated_zshrc=0

  if ! grep -q "aliases\.zsh" "$zshrc_file"; then
    {
      print "\n# Carregamento de aliases do usuário"
      print "$aliases_line"
    } >> "$zshrc_file"
    print -P "  %F{green}✓%f Linha do %F{cyan}aliases.zsh%f adicionada ao %F{yellow}~/.zshrc%f."
    updated_zshrc=1
  fi

  if ! grep -q "bundle\.zsh" "$zshrc_file"; then
    {
      print "\n# Carregamento do bundle zombierc"
      print "$bundle_line"
    } >> "$zshrc_file"
    print -P "  %F{green}✓%f Linha do %F{cyan}bundle.zsh%f adicionada ao %F{yellow}~/.zshrc%f."
    updated_zshrc=1
  fi

  if (( updated_zshrc == 0 )); then
    print -P "  %F{green}✓%f %F{cyan}~/.zshrc%f já está configurado com bundle e aliases."
  fi
fi

# 10. Verificação amigável de shell padrão (sem sudo / intrusão)
if [[ "${SHELL:t}" != "zsh" ]]; then
  print -P "\n%F{yellow}%B[ AVISO ]%b O Zsh não está definido como seu shell padrão (atual: %F{cyan}${SHELL:t}%f)."
  print -P "Você pode alterar o shell padrão do seu usuário com:"
  print -P "  %F{green}chsh -s ${(q)commands[zsh]}%f"
  print -P "A mudança vai se refletir quando a sessão for reiniciada."
fi

# 11. Instruções finais
print -P "\n%F{green}%B✨ Configuração concluída com sucesso!%b%f"
print -P "Seu %F{yellow}~/.zshrc%f está pronto e configurado para carregar:"
print -P "  • Bundle consolidado: %F{cyan}${bundle_file}%f"
print -P "  • Aliases:            %F{cyan}${aliases_file}%f"
print -P "\nPara aplicar as alterações na sua sessão atual:"
print -P "  %F{green}source ~/.zshrc%f\n"
