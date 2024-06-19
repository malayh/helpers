inithelprs() { source "$HOME/.bashrc"; }

w() {
    while true; do
        tput clear;
        $@;
        sleep 1;
    done
}