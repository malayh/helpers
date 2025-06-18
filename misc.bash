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


