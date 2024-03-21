# sets the current namespace, if no namespace is provided, it sets the namespace to default
ksetns() { kubectl config set-context --current --namespace "${1:-default}"; }
kget() { kubectl get $@; }
kdesc() { kubectl describe  $@; }
kdel() { kubectl delete $@; }
klog() { kubectl logs -f --tail=50 $@; }
kbash() { kubectl exec -it $1 -- /bin/bash; }