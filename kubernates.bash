UTILITY_NAMESPACE="utilities"
UTILITY_POD="utilbuntu"


# sets the current namespace, if no namespace is provided, it sets the namespace to default
ksetns() { kubectl config set-context --current --namespace "${1:-default}"; }
kenvs() { kubectl config get-contexts; }
ksetenv() { kubectl config use-context "${1:-kubernetes-admin@kubernetes}"; }
kdelenv() { kubectl config delete-context $1;}

kget() { kubectl get $@; }
kdesc() { kubectl describe  $@; }
kdel() { kubectl delete $@; }
klog() {
    pod=$1;
    lines="${2:-100}";
    kubectl logs -f --tail=$lines $pod; 
}
kbash() {
    args="${1}"
    if [ -n "$2" ]; then
        args="${1} --container $2"
    fi

    kubectl exec -it $args -- /bin/bash;
    if [ $? -gt 0 ]; then
        echo "No bash shell found in the container, trying sh";
        kubectl exec -it $args -- /bin/sh;
    fi
}
kcurrentns() { kubectl config view --minify --output 'jsonpath={..namespace}'; };
kedit() { kubectl edit $@; }
kread() { 
    path=$(echo $3 | sed 's/\./\\\./g');
    kubectl get $1 $2 -o jsonpath="{.data.$3}" 
}
ktop() { kubectl top $@; }

kgetdnsrecord() {
    #
    # Get dns records for all services/pods in the cluster
    #

    local current_ns=$(kcurrentns);

    kget ns $UTILITY_NAMESPACE || kubectl create ns $UTILITY_NAMESPACE;
    ksetns $UTILITY_NAMESPACE;

    kubectl get pods | grep $UTILITY_POD || {
        kubectl run $UTILITY_POD --image=ubuntu -- bash -c "while true; do echo hello; sleep 10; done";
        kubectl wait --for=condition=Ready pod/$UTILITY_POD --timeout=120s;
        kubectl exec -it $UTILITY_POD -- apt-get update;
        kubectl exec -it $UTILITY_POD -- apt install -y dnsutils;
    }

    kubectl get svc -A|egrep -v 'CLUSTER-IP|None'|awk '{print $4}'|sort -V > /tmp/ips.txt;
    kubectl get pod -A -o custom-columns=IP:status.podIP |egrep -v 'IP' | sort -V >> /tmp/ips.txt;
    kubectl cp /tmp/ips.txt ${UTILITY_POD}:/

    echo "===== DNS records ====="
    for ip in $(cat /tmp/ips.txt); do 
        echo -en "$ip \t";
        kubectl exec -it $UTILITY_POD -- dig -x $ip +short; 
    done
    echo "======================="

    rm /tmp/ips.txt;
    ksetns $current_ns;
}
kremoveutilpod() {
    # removes utility pod
    kdel pod $UTILITY_POD -n $UTILITY_NAMESPACE;
}

kdelcompleted() {
    kubectl get pods | grep Completed | cut -f1 -d' ' | xargs kubectl delete pod;
}

_completion_envs() {
    local current_word="${COMP_WORDS[COMP_CWORD]}"
    local suggestions=($(kubectl config get-contexts | awk '{print $2}' | grep -v NAME))
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$current_word"))
}

_completion_pods() {
    local current_word="${COMP_WORDS[COMP_CWORD]}"
    local suggestions=($(kubectl get pods | awk '{print $1}' | grep -v NAME))
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$current_word")) 
}

_completion_namespace() {
    local current_word="${COMP_WORDS[COMP_CWORD]}"
    local suggestions=($(kubectl get ns | awk '{print $1}' | grep -v NAME))
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$current_word")) 
}


complete -F _completion_envs ksetenv;
complete -F _completion_pods klog;
complete -F _completion_pods kbash;
complete -F _completion_namespace ksetns;