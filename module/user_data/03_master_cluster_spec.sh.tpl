echo "== nodeup node config starting =="
ensure-install-dir

cat > cluster_spec.yaml << '__EOF_CLUSTER_SPEC'
cloudConfig: null
docker:
  ipMasq: false
  ipTables: false
  logDriver: json-file
  logLevel: warn
  logOpt:
  - max-size=10m
  - max-file=5
  storage: overlay2,overlay,aufs
  version: ${docker_version}
encryptionConfig: null
etcdClusters:
  events:
    cpuRequest: 100m
    memoryRequest: 100Mi
    version: ${etcd_version}
  main:
    cpuRequest: 200m
    memoryRequest: 100Mi
    version: ${etcd_version}
kubeAPIServer:
  allowPrivileged: true
  anonymousAuth: false
  apiServerCount: ${master_count}
  authorizationMode: RBAC
  cloudProvider: aws
  bindAddress: 0.0.0.0
  enableAdmissionPlugins:
  - NamespaceLifecycle
  - LimitRanger
  - ServiceAccount
  - PersistentVolumeLabel
  - DefaultStorageClass
  - DefaultTolerationSeconds
  - MutatingAdmissionWebhook
  - ValidatingAdmissionWebhook
  - NodeRestriction
  - ResourceQuota
  disableBasicAuth: true
  etcdServers:
  - http://127.0.0.1:4001
  etcdServersOverrides:
  - /events#http://127.0.0.1:4002
  image: k8s.gcr.io/kube-apiserver:v${kubernetes_version}
  insecureBindAddress: 127.0.0.1
  insecurePort: 8080
  kubeletPreferredAddressTypes:
  - InternalIP
  - Hostname
  - ExternalIP
  logLevel: 2
  requestheaderAllowedNames:
  - aggregator
  requestheaderExtraHeaderPrefixes:
  - X-Remote-Extra-
  requestheaderGroupHeaders:
  - X-Remote-Group
  requestheaderUsernameHeaders:
  - X-Remote-User
  securePort: 443
  serviceClusterIPRange: 100.64.0.0/13
  storageBackend: ${storage_backend}
kubeControllerManager:
  allocateNodeCIDRs: true
  attachDetachReconcileSyncPeriod: 1m0s
  cloudProvider: aws
  clusterCIDR: 100.96.0.0/11
  clusterName: ${cluster_fqdn}
  configureCloudRoutes: false
  image: k8s.gcr.io/kube-controller-manager:v${kubernetes_version}
  leaderElection:
    leaderElect: true
  logLevel: 2
  useServiceAccountCredentials: true
kubeProxy:
  clusterCIDR: 100.96.0.0/11
  cpuRequest: 100m
  hostnameOverride: '@aws'
  image: k8s.gcr.io/kube-proxy:v${kubernetes_version}
  logLevel: 2
kubeScheduler:
  image: k8s.gcr.io/kube-scheduler:v${kubernetes_version}
  leaderElection:
    leaderElect: true
  logLevel: 2
kubelet:
  allowPrivileged: true
  anonymousAuth: false
  authorizationMode: Webhook
  authenticationTokenWebhook: true
  cgroupRoot: /
  cloudProvider: aws
  clusterDNS: 100.64.0.10
  clusterDomain: cluster.local
  enableDebuggingHandlers: true
  evictionHard: memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5%,imagefs.available<10%,imagefs.inodesFree<5%
  featureGates:
    ExperimentalCriticalPodAnnotation: "true"
  hostnameOverride: '@aws'
  kubeconfigPath: /var/lib/kubelet/kubeconfig
  logLevel: 2
  networkPluginName: cni
  nonMasqueradeCIDR: 100.64.0.0/10
  podInfraContainerImage: k8s.gcr.io/pause-amd64:3.0
  podManifestPath: /etc/kubernetes/manifests
masterKubelet:
  allowPrivileged: true
  anonymousAuth: false
  authorizationMode: Webhook
  authenticationTokenWebhook: true
  cgroupRoot: /
  cloudProvider: aws
  clusterDNS: 100.64.0.10
  clusterDomain: cluster.local
  enableDebuggingHandlers: true
  evictionHard: memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5%,imagefs.available<10%,imagefs.inodesFree<5%
  featureGates:
    ExperimentalCriticalPodAnnotation: "true"
  hostnameOverride: '@aws'
  kubeconfigPath: /var/lib/kubelet/kubeconfig
  logLevel: 2
  networkPluginName: cni
  nonMasqueradeCIDR: 100.64.0.0/10
  podInfraContainerImage: k8s.gcr.io/pause-amd64:3.0
  podManifestPath: /etc/kubernetes/manifests
  registerSchedulable: false

__EOF_CLUSTER_SPEC
