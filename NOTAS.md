Eu apaguei sem querer o ultimo arquivo.

Esse projeto surge como uma forma experimentação com a programação com o
auxilio de IA generativa ( Vibecode ) 

Eu quero fazer algo mais bem trabalhado, para que em novas intalações de linux, bsd ou até macOS
seja possivel apenas rodar um script de instalação e ele deixe o meu setup ZSH pronto.

São poucas os plugins que utilizo, e partindo disso eu gostaria de criar um micro gerenciador de plugin

Um outro ponto é o pure prompt que pode ser tratado como plugin.

O tempo de inicialização do zsh é um ponto interessante, eu não quero abrir o meu terminal e ter que
experar um istante até o zsh carregar.

Sobre a usabilidade eu gostaria de rodar o clássico:
[ "curl htt.../install.zsh | zsh" ] e aí ter o meu setup zsh pronto

O fish tem muitas coisas já prontas, mas não segue o padrão POSIX e eu tive problemas com o node e o SDKMAN
por isso o meu foco no ZSH.

Não tenho um motivo muito forte pra não experimentar o BASH ou outro shell.

Eu uso o zsh há muito tempo e gosto dele.

OHMYZSH! é lento.

Quero utilizar um recurso de "compilação" do zsh com word codes e tal.

Não quero que o script troque o shell padrão e nem faça nenhuma atividade que exija sudo

================================================================================================  

================================================================================================  

Velocidade e simplicidade é o objetivo

Talvez ainda fique um tempo minusculo de cold start

são três grandes coisas que me vem a mente, o instalador, o desistalador, e o carregador de plugins

O instalador baixa os plugins e mais o que tem que ser baixador, cria a arvore de diretórios e arquivos,
gera um super arquivão dos plugins, o chamado bundle que sera compilado para o plugins.zsh.zwc e será carregado

Eu quero utilizar as localalizoes .cache para o arquivo .zwc, ~/.local/share/zsh/plugins para os repos e o
~/.config/zsh/ com o zshrc e o aliases.zsh(acho que vou empacota-lo no bundle também)

O desistalador deve ter uma flag que mostra o que seria apagado.

O script será totalmente linear e dependerá só do git e o zsh para funcionar.
O meu setup é dependente de outros 2 programas( eza bat )

O script deve alertar a falta do eza e do bat ( por conta dos aliases ).

Preciso lidar com pager e o colored man 

O programa deve ser defencivo, tratando erros.

Existe uma ordem certa para carregar a extensões, acho que isso vai refletir no bundle.

O pure prompt precisa estar no fpath, {> ordem aqui é importante também? }
e ele precisa do `autoload` 
[ autoload -Uz promptinit && promptinit prompt pure ] {> O que o -Uz faz? }

Os plugins serão hardcoded no código.

[set -euo pipefail] ????



================================================================================================  

================================================================================================  
[ set -e ]     - # O shell vai rodando e se aparece um erro ele continua sem se importar com o erro
                  essa opção impede esse comportamento.

[ command -v ] - # Util para verificar se um comando está instalado. 

[ zcompile ]   - # Comando que promente acelerar o load do zsh
                   ele tira o parsing da jogada.
================================================================================================  

================================================================================================  
[ ctrl + r ] |> atalho para procurar comandos no histórico.


================================================================================================  

================================================================================================  
Crie um script zsh que crie crie um setup zsh, o script deve baixar alguns plugins que estão denro de uma lista
no script. O script deve baixar os plugins em ~/.local/share/zsh/plugins. Com os plugins baixados o script deve
agrupar todos os arquivos.zsh dos plugins em um bundle. O script deve compilar esse bundle zsh com o zcompile e
guardar o .zwc no ~/.cache 

 








