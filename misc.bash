initbash() { source "$HOME/.bashrc"; }

w() {

    while true; do
        eval "$@" > /tmp/w.out;    
        tput clear;
        cat /tmp/w.out;
        sleep 1;
    done
}