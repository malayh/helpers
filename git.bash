# Pushes current branch from origin
gpoc() { git push origin $(git rev-parse --abbrev-ref HEAD) $@; }

# Pulls current branch from origin
gpull() { git pull origin $(git rev-parse --abbrev-ref HEAD) $@; }