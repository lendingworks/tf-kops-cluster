cat > ig_spec.yaml << '__EOF_IG_SPEC'
kubelet:
  imagePullProgressDeadline: 1h0m0s
nodeLabels:
  kops.k8s.io/instancegroup: ${instance_group}
taints: null

__EOF_IG_SPEC
