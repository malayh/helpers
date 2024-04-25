UTILITY_NAMESPACE="utilities"
UTILITY_POD="utilbuntu"

# sets the current namespace, if no namespace is provided, it sets the namespace to default
ksetns() { kubectl config set-context --current --namespace "${1:-default}"; }
kget() { kubectl get $@; }
kdesc() { kubectl describe  $@; }
kdel() { kubectl delete $@; }
klog() { kubectl logs -f --tail=50 $@; }
kbash() { kubectl exec -it $1 -- /bin/bash; }
kcurrentns() { kubectl config view --minify --output 'jsonpath={..namespace}'; };
kgetdnsrecord() {
    #
    # Get dns records for all services in the cluster
    #

    local current_ns=$(kcurrentns);

    kget ns $UTILITY_NAMESPACE || kubectl create ns $UTILITY_NAMESPACE;
    ksetns $UTILITY_NAMESPACE;

    kubectl get pods | grep $UTILITY_POD || {
        kubectl run $UTILITY_POD --image=ubuntu -- bash -c "while true; do echo hello; sleep 10; done";
        kubectl wait --for=condition=Ready pod/$UTILITY_POD --timeout=120s
    }

    kubectl get svc -A|egrep -v 'CLUSTER-IP|None'|awk '{print $4}'|sort -V > /tmp/ips.txt;
    kubectl cp /tmp/ips.txt ${UTILITY_POD}:/

    kubectl exec -it $UTILITY_POD -- apt-get update;
    kubectl exec -it $UTILITY_POD -- apt install -y dnsutils;

    echo "===== DNS records ====="
    for ip in $(cat /tmp/ips.txt); do 
        echo -n "$ip ";
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