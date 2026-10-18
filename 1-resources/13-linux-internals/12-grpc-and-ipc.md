# 12. gRPC + ipc — the protocol every arrow in this stack is drawn with

related: [00-index](00-index.md) · prev: [11-cri-and-kubelet](11-cri-and-kubelet.md) · next: [13-erofs](13-erofs.md) · used by: [10-containerd-internals](10-containerd-internals.md) (client↔daemon, daemon↔shim), [11-cri-and-kubelet](11-cri-and-kubelet.md) (kubelet↔containerd) · contrast with: [02-namespaces](02-namespaces.md) (ipc *namespace*, a different meaning of "ipc")

## two unrelated things both called "ipc" — disambiguate first

this stack uses the word "ipc" for two genuinely different concepts, and
conflating them causes real confusion:

1. the **IPC kernel namespace** ([02-namespaces](02-namespaces.md#ipc-namespace))
   — isolates System V shared memory segments, message queues, and
   semaphores *inside* a container. this is about one container's
   processes not seeing another's SysV IPC objects.
2. **inter-daemon IPC** (this file) — how separate long-lived processes on
   the *same host* (kubelet, containerd, a shim, dockerd) talk to each
   other at all. this has nothing to do with SysV IPC or the ipc namespace
   — it's implemented as **gRPC over unix domain sockets**.

every arrow drawn between boxes in [00-index](00-index.md)'s diagram —
kubelet→containerd, `ctr`→containerd, containerd→shim — is an instance of
sense 2.

## why unix sockets, not TCP

containerd's API, the CRI plugin, and the shim protocol all listen on
**unix domain sockets** (e.g. `/run/containerd/containerd.sock`), not TCP
ports. this is deliberate: these are host-local daemons only ever talked to
by other processes on the same machine, so a unix socket gives you
filesystem-permission-based access control for free (whoever can read/write
the socket file can talk to the daemon) without opening any network-
reachable port at all.

## what "gRPC" actually is

gRPC is a specific way of building this kind of client/server API:

- **protobuf** (Protocol Buffers) defines the schema — request/response
  message shapes and the set of RPC methods — in a `.proto` file, which is
  then compiled into strongly-typed client and server code for whatever
  languages you need (Go for containerd/kubelet, Rust via `tonic`, etc).
  everyone talking to the same socket agrees on the exact same generated
  types, because they were generated from the same `.proto` source.
- **HTTP/2** is the underlying transport — this matters specifically
  because HTTP/2 supports multiplexed, bidirectional **streaming**, not
  just simple request/response. this is what makes `Exec`/`Attach`/log
  streaming ([11-cri-and-kubelet](11-cri-and-kubelet.md#the-two-cri-services))
  possible over the same protocol as ordinary unary calls like
  `ListContainers`.
- binary encoding (protobuf's wire format) is compact and fast to
  (de)serialize compared to, say, JSON-over-HTTP, which matters when a
  node's kubelet is polling container/pod status frequently.

a minimal illustrative shape of what a `.proto` service definition looks
like (this is the *pattern* CRI/containerd APIs follow, simplified):

```protobuf
service RuntimeService {
  rpc RunPodSandbox(RunPodSandboxRequest) returns (RunPodSandboxResponse);
  rpc ListContainers(ListContainersRequest) returns (ListContainersResponse);
  rpc Exec(ExecRequest) returns (ExecResponse);       // often streaming
}
```

the real CRI proto is at https://github.com/kubernetes/cri-api — same
idea, much larger surface.

## the full chain, all gRPC, all the way down

- **containerd's native API** — Containers, Tasks, Images, Content,
  Snapshots, Events, Leases services, all gRPC over
  `/run/containerd/containerd.sock`. `ctr`, `nerdctl`, and dockerd's own
  containerd client are all just gRPC clients against this.
- **the CRI plugin** inside containerd exposes `RuntimeService`/
  `ImageService` — also gRPC, on the same socket, and this is exactly what
  kubelet is a client of (see
  [11-cri-and-kubelet](11-cri-and-kubelet.md)).
- **the shim v2 protocol** (containerd daemon ↔ `containerd-shim-runc-v2`)
  is its *own* small API, also generated from proto definitions, also
  effectively gRPC-shaped, running over a unix socket unique to that
  container's shim instance. this is how containerd, after restarting,
  reconnects to already-running shims and recovers state about containers
  it didn't itself keep alive (see
  [10-containerd-internals](10-containerd-internals.md#why-shims-exist)).

so at every layer of this stack — client tools, kubelet, containerd, and
even containerd talking to its own shims — the mechanism is the same: a
`.proto`-defined gRPC service over a local unix socket.

## why this matters for the rust/tonic angle

**tonic** is a gRPC implementation for Rust: given a `.proto` file, it
code-generates client (and server) stubs, the same way Go's `protoc-gen-go-
grpc` does for containerd/kubelet. because CRI's entire surface is just a
public `.proto` file (https://github.com/kubernetes/cri-api), writing a
Rust client against a real, running containerd's CRI socket is not a toy
exercise — it's speaking the exact protocol kubelet speaks, just from a
different language's generated stubs. that's the premise behind mini
project b in [../tinklerbox.md](../tinklerbox.md): point `tonic-build` at
the CRI proto, generate a client, and call `ListContainers` against
`/run/containerd/containerd.sock` for real.

## references

- gRPC: https://grpc.io/
- containerd API protos: https://github.com/containerd/containerd/tree/main/api
- CRI-api protos: https://github.com/kubernetes/cri-api
- tonic: https://github.com/hyperium/tonic

## hands-on

- `grpcurl -plaintext -unix /run/containerd/containerd.sock list` (or the
  unix-socket-flavored equivalent for your grpcurl version) to enumerate
  the gRPC services containerd actually exposes on that socket, live.
- scaffold a minimal `tonic-build` project pointed at the real CRI proto,
  generate the client stubs, and call `ListContainers` or `ListImages`
  against a local containerd's socket — the smallest possible version of
  mini project b.
- `strace -f -e trace=network,connect crictl ps` (or equivalent) to
  confirm kubelet/crictl-style tools really are just connecting to a unix
  socket path, not opening any TCP port, when they talk CRI.
