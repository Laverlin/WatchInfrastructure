kubectl run -it --image radial/busyboxplus:curl --overrides='{"apiVersion": "v1", "spec": {"nodeSelector": { "kubernetes.io/hostname": "montalcino-worker-vm" }}}' ping-pod -- sh
