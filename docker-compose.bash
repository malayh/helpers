# Runs all or mentions service(s) in the current docker-compose.yml in the background
dup() { docker-compose up -d $@; }

# Kills all or mentions service(s) in the current docker-compose.yml
ddown() { echo $@ ; docker-compose down $@; }

# Shows logs of all or mentions service(s) in the current docker-compose.yml
dlog() { docker-compose logs -f $1; }

# Shows status of all or mentions service(s) in the current docker-compose.yml
dps() { docker-compose ps; }

# Get a shell to mentioned service
dbash(){ docker-compose exec $1 bash; }