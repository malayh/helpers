initbash() { source "$HOME/.bashrc"; }

passgen() {
    length=${1:-12}
    echo $(head -c $length /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
}

w() {
    local tmpfile=$(mktemp) || return 1
    
    while true; do
        eval "$@" > "$tmpfile";    
        tput clear;
        cat "$tmpfile";
        sleep 1;
    done
}


