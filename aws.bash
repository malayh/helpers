function asetenv() {
    # Checks the ~/.bashrc file if it has line export AWS_PROFILE=<value> if it does, replace it with the new value, if it doesn't add it to the end of the file.
    local profile_value="$1"
    local bashrc_file="$HOME/.bashrc"
    local export_line="export AWS_PROFILE=${profile_value}"

    grep -q "^export AWS_PROFILE=" "$bashrc_file" && { 
        sed -i.bak "s|^export AWS_PROFILE=.*|$export_line|" "$bashrc_file";
    } || {
        echo "$export_line" >> "$bashrc_file";
    }
    source "$bashrc_file";
}

function aenvs() {
    # Lists all the AWS profiles in the ~/.aws/credentials file.
    grep -E '^\[.*\]' "$HOME/.aws/config" | sed 's/[][]//g';
    # echo current profile
    echo "Current profile: $AWS_PROFILE";
}

function averify() {
    aws sts get-caller-identity;
}