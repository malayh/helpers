dc () { docker-compose $@; }
dtop() { docker-compose stats; }


# Runs all or mentions service(s) in the current docker-compose.yml in the background
dup() { docker-compose up -d $@; }

# Kills all or mentions service(s) in the current docker-compose.yml
ddown() { echo $@ ; docker-compose down $@; }

# Shows logs of all or mentions service(s) in the current docker-compose.yml
dlog() { docker-compose logs -f $1; }

# Shows status of all or mentions service(s) in the current docker-compose.yml
dps() { docker-compose ps; }

# Get a shell to mentioned service
dbash(){ 
    docker-compose exec $1 bash; 
    if [ $? -gt 0 ]; then
        echo "No bash shell found in the container, trying sh";
        docker-compose exec $1 sh;
    fi
}

_completion_service_list() {
    local current_word="${COMP_WORDS[COMP_CWORD]}"
    local suggestions=($(docker-compose ps --services))
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$current_word"))
}

# Register the completion function to be called for dlog
complete -F _completion_service_list dup;
complete -F _completion_service_list ddown;
complete -F _completion_service_list dlog;
complete -F _completion_service_list dbash;
