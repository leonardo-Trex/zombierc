- Verificar a disponibilidade dos programas necessários [  ]
    - Alertar ao usuário a falta do zsh [  ]  
    - Alertar o usuário a falta do git [  ]

- Sistemas de download do github [  ]
    - Verificar a estrutura de pastas ( XDG ) ( home, cache, config, state ) [  ]
        - Criar a estrutura de pastas se for preciso [  ]
    - Baixar os plugins ( git clone ) no lugar correto ( ~/.config/zsh/plugins ) [  ]
    - 

- Sistema de carregamento de plugins [  ]
    - Sistema de compilação de plugins ( zcompile ) [  ]
        - Localizar o arquivo do plugins [  ]
        - Compilar o plugin [  ]
        - Guardar o compilado na pasta cache [  ]
        - Carregar esse cache compilado do plugin [  ]
        - Criar o symlink ( `~/.zshrc` ) apontando para o ( `~/.config/zsh/zshrc` )

- Sistema de carregamento de alias
    - Gera o zshrc e consome o aliases.zsh

- Sistema de apresentação do programa executando
    - Info do repositório que está sendo baixado [  ]

## SEM SUDO!!
O sistema deve apenas alertar que o zsh não é o shell padrão e exibir o 
comando que pode ser utilizado para trocar o shell:

- `sudo chsh -s $(which zsh)` 

## Pure prompt...
- Baixar o pure prompt e suas dependências...
- Salvar em ( `~/.config/zsh/prompts` )
- Carregar o prompt { Não sei a efetividade do zcompile aqui }

# No futuro...
- Verificar atualizações.
