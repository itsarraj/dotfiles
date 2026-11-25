# 6. networking — netns, veth, nat, cni, and port handling

related: [00-index](00-index.md) · prev: [05-security-capabilities-seccomp-lsm](05-security-capabilities-seccomp-lsm.md) · next: [07-container-creation-steps](07-container-creation-steps.md) · builds on: [02-namespaces](02-namespaces.md) (network namespace) · connects to: [11-cri-and-kubelet](11-cri-and-kubelet.md) (pod sandbox owns the netns; CNI invoked at sandbox creation)

## the split: kernel piece vs userspace piece

the **network namespace** ([02](02-namespaces.md)) is the only kernel
primitive involved here — it gives a process its own interfaces, routes,
netfilter rules, and sockets. everything about actually *connecting* that
isolated namespace to the outside world — bridges, veth pairs, NAT rules,
IP address assignment — is ordinary userspace networking configuration
layered on top. the kernel doesn't know or care that this is "for a
container"; it's the same primitives you'd use to build any isolated
network segment.

## veth pairs — the virtual ethernet cable

a **veth pair** is two virtual network interfaces that are always created
together and always connected to each other — anything sent in one comes
out the other, like a virtual patch cable. the standard container wiring:

1. create a veth pair, e.g. `veth0`/`veth0-host`.
2. move one end (`veth0`) into the container's network namespace via
   `ip link set veth0 netns <pid>`, then rename it `eth0` inside.
3. leave the other end (`veth0-host`) on the host side, and attach it to a
   **bridge** (docker's default is `docker0`) — a software L2 switch the
   kernel implements — so every container's host-side veth end and the
   host's own uplink are all on the same virtual segment.
4. the bridge (or, in more advanced setups, direct routing) handles getting
   packets between containers and out to the real network.

alternative to bridging: **routed** setups (no bridge, host routes traffic
to each container's IP directly) — common in some CNI plugins (e.g. Calico
in non-overlay mode) for better performance/simpler debugging at the cost
of needing route propagation across nodes.

## nat / firewalling

`iptables`/`nftables` (depending on distro/version) provide the NAT and
forwarding rules that let containers reach the outside world and let the
outside world reach specific container ports. this is exactly the
mechanism described below under port mapping — there's no separate "docker
networking stack," it's standard netfilter rules that docker/kube-proxy
programmatically manage for you.

## cni — the pluggable model kubernetes uses

kubernetes doesn't hardcode a networking implementation; it defines the
**Container Network Interface (CNI)**, a small plugin contract: given a
network namespace and some config, a CNI plugin's job is to wire that
namespace into the cluster network and report back the assigned IP. plugins
implementing this contract include bridge, calico, cilium, flannel, and
others — they differ wildly in mechanism (VXLAN overlays, BGP-routed,
eBPF-based, ...) but all present the same plugin interface to the runtime.
CNI plugins are invoked **at pod sandbox creation time** — see
[11-cri-and-kubelet](11-cri-and-kubelet.md) for exactly where in the
CRI call sequence this happens.

## port handling — how a port actually gets "allocated" to a container

a container does not inherently "own" a host port. it only ever binds a
port inside its own, isolated network namespace. anything that looks like
"the container is listening on host port 8080" is actually NAT: packets
arriving at the host on 8080 get their destination rewritten to the
container's namespace-local IP and port before the kernel routes them
further.

### docker's `-p hostPort:containerPort`

1. the container has a veth end (`eth0` inside its netns) with its own IP,
   reachable from the host's bridge network but not from outside the host.
2. docker programs an iptables **NAT table, `DOCKER` chain** rule: incoming
   packets to `hostIP:hostPort` get DNAT'd (destination rewritten) to
   `containerIP:containerPort`. the kernel's normal routing then delivers
   the packet into the bridge, across the veth pair, into the container's
   namespace.
3. **`docker-proxy`** is a userspace fallback process docker can run instead
   of (or alongside) the iptables path, for situations where a pure NAT
   rule doesn't cleanly cover the case (historically relevant for some
   `localhost`-only binding edge cases, and on some non-Linux docker
   backends). on a normal modern Linux host, the iptables path does the
   real work and `docker-proxy` is often not actually in the data path.

### kubernetes

- every **pod** gets its own cluster-routable IP via CNI — this is a
  deliberate design choice so that, unlike plain docker, most traffic
  *doesn't need host-port NAT at all*: pod-to-pod communication just routes
  directly, pod IP to pod IP, across the cluster network.
- **`Service`** objects (`ClusterIP`, `NodePort`, `LoadBalancer`) are
  implemented by **kube-proxy**, running in one of two main modes:
  - *iptables mode* — programs `DNAT`/load-balancing rules mapping
    `ServiceIP:port` to one of the backing `PodIP:targetPort`s, picked
    (pseudo-)randomly per new connection via iptables' statistic module.
  - *IPVS mode* — uses the kernel's IP Virtual Server subsystem instead,
    which scales better with very large numbers of services (iptables rule
    evaluation is roughly linear in rule count; IPVS uses hash tables).
  - `NodePort` additionally opens the same port on **every node** in the
    cluster and DNATs to the service, so any node's IP can be used as an
    entry point regardless of where the actual pod is running.
- **pod-spec `hostPort`** is the direct k8s analog of docker's `-p` flag —
  a container asks to bind a specific port on the *node's* host network
  namespace directly. it's implemented by the CNI **`portmap`** plugin,
  which installs the equivalent iptables DNAT rule at sandbox-creation
  time. this is rarely used compared to `Service`s, precisely because it
  reintroduces the "one port per node" scheduling constraint that pod IPs
  were designed to avoid.

## references

- man pages: `network_namespaces(7)`
- `ip(8)` (iproute2 suite — `ip link`, `ip netns`, `ip addr`, `ip route`)
- `iptables(8)` / `nft(8)` depending on your distro's netfilter frontend
- CNI spec: https://github.com/containernetworking/cni
- kube-proxy modes: https://kubernetes.io/docs/reference/networking/virtual-ips/

## hands-on

- build a veth pair by hand: `ip link add veth0 type veth peer name veth1`,
  move `veth1` into a network namespace created via `ip netns add`, assign
  IPs on both ends, and ping across it — this is the entire mechanism
  behind container networking, done manually.
- run a container with `-p 8080:80` and inspect the actual `iptables -t nat
  -L DOCKER -n` rule that gets created; delete it manually and watch the
  port mapping stop working, to prove to yourself it's "just" a NAT rule.
- on a k8s node, run `iptables-save | grep <service-name>` (iptables mode)
  or `ipvsadm -Ln` (IPVS mode) after creating a `Service`, to see kube-proxy's
  generated rules directly.
