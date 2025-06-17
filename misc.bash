initbash() { source "$HOME/.bashrc"; }

passgen() {
    length=${1:-12}
    echo $(head -c $length /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
}

w() {

    while true; do
        eval "$@" > /tmp/w.out;    
        tput clear;
        cat /tmp/w.out;
        sleep 1;
    done
}


_completion_justfile() {
    local current_word="${COMP_WORDS[COMP_CWORD]}"
    local suggestions=($(just --summary))
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$current_word")) 
}
complete -F _completion_justfile just;

