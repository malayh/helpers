inithelprs() { source "$HOME/.bashrc"; }

w() {

    while true; do
        $@ > /tmp/w.out;    
        tput clear;
        cat /tmp/w.out;
        sleep 1;
    done
}