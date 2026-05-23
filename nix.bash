function ninstall() {
    cwd=$(pwd);
    cd $(cat /etc/nixos/flake-root) && ./install.sh && cd $cwd
}

function nhome() {
    cd $(cat /etc/nixos/flake-root)
}