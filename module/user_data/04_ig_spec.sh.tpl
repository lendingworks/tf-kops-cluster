cat > ig_spec.yaml << '__EOF_IG_SPEC'
kubelet:
  imagePullProgressDeadline: 1h0m0s
nodeLabels:
  kops.k8s.io/instancegroup: ${instance_group}
  k8s.io/spot-worker: "${is_spot}"
taints: null

__EOF_IG_SPEC
