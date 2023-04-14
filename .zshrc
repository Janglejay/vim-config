# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/fufangjie/.oh-my-zsh"

export JET_SHELL="/Users/fufangjie/Documents/jetbrains_shell"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="jonathan"
ZSH_THEME="robbyrussell"
# ZSH_THEME="af-magic"

# ZSH_THEME="apple"
# ZSH_THEME="kafeitu"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=( 
    git
    # other plugins...
    zsh-autosuggestions
    zsh-syntax-highlighting 
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

export V_S=/Users/fufangjie/Documents/Learn/vocational_skills
export MAVEN_HOME=/opt/maven/apache-maven-3.9.1
export PATH=$PATH:$MAVEN_HOME/bin

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home

export S="/Users/fufangjie/Documents/Shell"
export T="/Users/fufangjie/Documents/tmp"
export NEO_VIM="/Users/fufangjie/.config/nvim/"
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-16.jdk/Contents/Home


# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias cc='cd /Users/fufangjie/Company/JavaProjects'
alias cm='cd /Users/fufangjie/MyProjects'
alias cdd='cd /Users/fufangjie/Documents'
alias cn='cd $NEO_VIM'
alias cs='cd $S'
alias ct='cd $T'
alias cg='cd /Users/fufangjie/MyProjects/go_project'
alias cr='cd /Users/fufangjie/MyProjects/rust_project'
alias cj='cd /Users/fufangjie/MyProjects/java_project'

alias t='tmux'

alias ej='source $S/edit_file.sh json'
alias et='source $S/edit_file.sh txt'
alias em='source $S/edit_file.sh md'
alias el='source $S/edit_file.sh lua'
alias es='source $S/edit_file.sh sh'

alias vim='nvim'
alias vi='nvim'

alias sd='source $S/format_date.sh'
alias cl='source $S/goto_learn.sh'
alias cll='cd /Users/fufangjie/Documents/Learn'

alias tt='source $S/tran.sh zh'
alias te='source $S/tran.sh en'

# mysql command
export MYSQL_HOME=/usr/local/mysql
alias mysql=$MYSQL_HOME/bin/mysql

#jetbrain shell
alias idea=$JET_SHELL/idea
alias fleet=$JET_SHELL/fleet

# open command vim mode edit
# website: http://bolyai.cs.elte.hu/zsh-manual/zsh_14.html
# bindkey -v
# bindkey -M vicmd "H" vi-beginning-of-line
# bindkey -M vicmd "L" vi-end-of-line
# bindkey -M vicmd "k" history-beginning-search-backward
# bindkey -M vicmd "j" history-beginning-search-forward
# bindkey -M viins "jk" vi-cmd-mode

# Change cursor shape for different vi modes.
# function zle-keymap-select {
#   if [[ ${KEYMAP} == vicmd ]] ||
#      [[ $1 = 'block' ]]; then
#     echo -ne '\e[1 q'
# 
#   elif [[ ${KEYMAP} == main ]] ||
#        [[ ${KEYMAP} == viins ]] ||
#        [[ ${KEYMAP} = '' ]] ||
#        [[ $1 = 'beam' ]]; then
#     echo -ne '\e[5 q'
#   fi
# }
# zle -N zle-keymap-select

# Use beam shape cursor on startup.
# echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
# preexec() {
#    echo -ne '\e[5 q'
# }

# git config
alias gcm='source $S/commit.sh'
alias gcm='source $S/commit.sh real_commit'
alias gc='git checkout'
alias gs="git status"

# anaconda
export PATH="/opt/homebrew/anaconda3/bin:$PATH"

# system
alias pc='pbcopy'
alias pp='pbpaste'

# tree
alias tl='tree -L'
