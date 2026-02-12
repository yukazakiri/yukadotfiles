#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# ii shell integration
[[ -f ~/.config/ii/bashrc ]] && source ~/.config/ii/bashrc

# Add yadm to PATH if installed locally
export PATH="$HOME/.local/bin:$PATH"
