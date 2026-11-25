---
id: 20250328154255
title: Complete Intro to Containers Docker Frontend Masters Course
date: 2025-03-28 15:43
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [docker, containers, frontend-masters, tutorial, devops]
links: []
---
# Log
- 2025-03-28 15:43 - Created note.

# Notes

# Complete Intro to Containers (feat. Docker)

# 01 Introduction.ts
# 02 Containers.ts
# 03 chroot.ts

download if not available, load up the vm and login into the shell
```bash
docker run -it --name docker-host --rm --privileged ubuntu:bionic
```
/etc/issue results in linux type with version
```bash
root@f071fc304359:/# cat /etc/issue
Ubuntu 18.04.6 LTS \n \l
```

```bash
root@f071fc304359:/# mkdir my-new-root
root@f071fc304359:/# cd my-new-root/
root@f071fc304359:/my-new-root# chroot . bash
chroot: failed to run command 'bash': No such file or directory
```
the error resulted because the new root environment does not have the bash in it.
```bash
root@f071fc304359:/my-new-root# mkdir bin
root@f071fc304359:/# cp bin/bash my-new-root/bin/
root@f071fc304359:/# ls my-new-root/bin/bash
my-new-root/bin/bash
```
even after adding bash, the result of error is it is missing libraries needed to run.
```bash
root@f071fc304359:/# chroot my-new-root/ bash
chroot: failed to run command 'bash': No such file or directory
```
Still not working! The problem is that these commands rely on libraries to power them and we didn't bring those with us. So let's do that too. Run ldd /bin/bash. This print out something like this:
```bash
root@f071fc304359:/# ldd bin/bash
        linux-vdso.so.1 (0x00007558ece31000)
        libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007558ec6bc000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007558ec4b8000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007558ec0c7000)
        /lib64/ld-linux-x86-64.so.2 (0x00007558ecc00000)
```
This was called jail before being called contianers.
ls, bash, cat and many other program, that exist in /bin/ have different dependencies on libraries. Run `ldd /bin/{program}` and replicate the paths with the libraries in chroot/jail environment.

`my notes` 
The reason linux-vdso.so.1 is not explicitly copied into the jailed root (or container's root filesystem) is because it is a virtual shared object (VDSO). It is not an actual file on disk but a memory region provided by the Linux kernel.

# 04 chroot Exercise.ts
# 05 chroot Solution.ts
# 06 Namespaces.ts

```bash
root@f071fc304359:/# ps
    PID TTY          TIME CMD
      1 pts/0    00:00:00 bash
     54 pts/0    00:00:00 ps
```

this is #1 shell with tail
```bash
root@cf5cd9d2b32d:/# echo "secret in file >> "  >> /my-new-root/secret.txt
root@cf5cd9d2b32d:/# pwd
/
root@cf5cd9d2b32d:/# ls
bin   dev  home  lib64  mnt          opt   root  sbin  sys  usr
boot  etc  lib   media  my-new-root  proc  run   srv   tmp  var
root@cf5cd9d2b32d:/# chroot my-new-root/ bash
bash-4.4# cat secret.txt
secret in file >>
```
run a loop process on #1 shell
```bash
root@cf5cd9d2b32d:/my-new-root# tail -f secret.txt
secret in file >>
Terminated
```

this is another #2 shell
```bash
[username@hostname notes]$  docker exec -it docker-host bash
root@cf5cd9d2b32d:/# pwd
/
root@cf5cd9d2b32d:/# ls
bin   dev  home  lib64  mnt          opt   root  sbin  sys  usr
boot  etc  lib   media  my-new-root  proc  run   srv   tmp  var
root@cf5cd9d2b32d:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18520  3100 pts/0    Ss   15:30   0:00 /bin/bash
root          55  0.0  0.0   4580  1308 pts/0    S+   15:38   0:00 tail -f secret.txt
root          56  0.2  0.0  18520  3348 pts/1    Ss   15:44   0:00 bash
root          67  0.0  0.0  34416  2776 pts/1    R+   15:45   0:00 ps aux
root@cf5cd9d2b32d:/# kill 55
```
This is a problem because that means chroot isn't enough to isolate someone.

## Safety with namespaces

using `unshare` to isolate the chroot environment, as `unshare` create a new isolated namespace from its parent and all other future child/tenent(having shared resourses).

debootstrap is a tool which will install a Debian base system into a subdirectory of another, already installed system
refer this wiki for debootstrap details: https://wiki.debian.org/Debootstrap

```bash
exit # from our chroot'd environment if you're still running it, if not skip this

# install debootstrap
apt-get update -y
apt-get install debootstrap -y
debootstrap --variant=minbase bionic /better-root

# head into the new namespace'd, chroot'd environment
unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot /better-root bash # this also chroot's for us
mount -t proc none /proc # process namespace
mount -t sysfs none /sys # filesystem
mount -t tmpfs none /tmp # filesystem
```

my hands-on example
```bash
root@d7a1cb5b3647:/better-root# unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot /better-root bash # this also chroot's for us
root@d7a1cb5b3647:/# ps aux
Error, do this: mount -t proc proc /proc
root@d7a1cb5b3647:/# mount -t proc none /proc # process namespace
root@d7a1cb5b3647:/# mount -t sysfs none /sys # filesystem
root@d7a1cb5b3647:/# mount -t tmpfs none /tmp # filesystem
```

This is isolated environment

this is the #1 shell with chroot /better-root
```bash
root@d7a1cb5b3647:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18512  3404 ?        S    23:37   0:00 bash
root          13  0.0  0.0  34404  2700 ?        R+   23:42   0:00 ps aux
root@d7a1cb5b3647:/# ls
bin   debootstrap  etc   lib    media  opt   root  sbin  sys  usr
boot  dev          home  lib64  mnt    proc  run   srv   tmp  var
root@d7a1cb5b3647:/# pwd
/
```

this is another #2 shell 
```bash
[username@hostname notes]$ docker exec -it docker-host bash
root@d7a1cb5b3647:/# pwd
/
root@d7a1cb5b3647:/# ls
better-root  boot  etc   lib    media  opt   root  sbin  sys  usr
bin          dev   home  lib64  mnt    proc  run   srv   tmp  var
root@d7a1cb5b3647:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18520  2932 pts/0    Ss   22:54   0:00 /bin/bash
root        7606  0.0  0.0   4532  1256 pts/0    S    23:37   0:00 unshare --mount --uts --ipc --net --p
root        7607  0.0  0.0  18512  3404 pts/0    S+   23:37   0:00 bash
root        7619  0.0  0.0  18520  3300 pts/1    Ss   23:40   0:00 bash
root        7629  0.0  0.0  34416  2704 pts/1    R+   23:40   0:00 ps aux
```

This is isolated environment
```bash
## This is 1st phase
root@d7a1cb5b3647:/# pwd
/
root@d7a1cb5b3647:/# touch inside-better-root
root@d7a1cb5b3647:/# tail -f inside-better-root
Terminated
## This is 2nd phase
root@d7a1cb5b3647:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18512  3404 ?        S    23:37   0:00 bash
root          22  0.0  0.0  34404  2732 ?        R+   23:58   0:00 ps aux
```

This is outside the better-root
```bash
## This is 1st phase
root@d7a1cb5b3647:/# pwd
/
root@d7a1cb5b3647:/# ls
better-root  boot  etc   lib    media  opt   root  sbin  sys  usr
bin          dev   home  lib64  mnt    proc  run   srv   tmp  var
root@d7a1cb5b3647:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0  18520  2932 pts/0    Ss   22:54   0:00 /bin/bash
root        7606  0.0  0.0   4532  1256 pts/0    S    23:37   0:00 unshare --mount --uts --ipc --net --p
root        7607  0.0  0.0  18512  3404 pts/0    S    23:37   0:00 bash
root        7619  0.0  0.0  18520  3300 pts/1    Ss   23:40   0:00 bash
root        7642  0.0  0.0   4572  1300 pts/0    S+   23:57   0:00 tail -f inside-better-root
root        7643  0.0  0.0  34416  2804 pts/1    R+   23:57   0:00 ps aux
root@d7a1cb5b3647:/# kill 7642
## This is 2nd phase
root@d7a1cb5b3647:/# touch outside-better-root
root@d7a1cb5b3647:/# tail -f outside-better-root
```

Note: this entire process of jail is for explanation of how the jail or container works. More like a academic exaplanation. Docker and other container tools  

# 07 cgroups.ts

in the docker we are using the cgroups used are v2 and cgcreate won't work, 
so for this chapter, I went through course without handson.
tried v2 syntax but was issue with permissions
```bash
# outside of unshare'd environment get the tools we'll need here
apt-get install -y cgroup-tools htop

# create new cgroups
cgcreate -g cpu,memory,blkio,devices,freezer:/sandbox

# add our unshare'd env to our cgroup
ps aux # grab the bash PID that's right after the unshare one
cgclassify -g cpu,memory,blkio,devices,freezer:sandbox <PID>

# list tasks associated to the sandbox cpu group, we should see the above PID
cat /sys/fs/cgroup/cpu/sandbox/tasks

# show the cpu share of the sandbox cpu group, this is the number that determines priority between competing resources, higher is is higher priority
cat /sys/fs/cgroup/cpu/sandbox/cpu.shares

# kill all of sandbox's processes if you need it
# kill -9 $(cat /sys/fs/cgroup/cpu/sandbox/tasks)

# Limit usage at 5% for a multi core system
cgset -r cpu.cfs_period_us=100000 -r cpu.cfs_quota_us=$[ 5000 * $(getconf _NPROCESSORS_ONLN) ] sandbox

# Set a limit of 80M
cgset -r memory.limit_in_bytes=80M sandbox
# Get memory stats used by the cgroup
cgget -r memory.stat sandbox

# in terminal session #2, outside of the unshare'd env
htop # will allow us to see resources being used with a nice visualizer

# in terminal session #1, inside unshared'd env
yes > /dev/null # this will instantly consume one core's worth of CPU power
# notice it's only taking 5% of the CPU, like we set
# if you want, run the docker exec from above to get a third session to see the above command take 100% of the available resources
# CTRL+C stops the above any time

# in terminal session #1, inside unshare'd env
yes | tr \\n x | head -c 1048576000 | grep n # this will ramp up to consume ~1GB of RAM
# notice in htop it'll keep the memory closer to 80MB due to our cgroup
# as above, connect with a third terminal to see it work outside of a cgroup
```

# 08 Getting Set Up with Docker.ts
# 09 Docker Images without Docker.ts

I have updated the PS1 varible from this point onwards so the bash prompt will look like this.
```bash
›
```

```bash
# start docker container with docker CLI in it connected to host docker daemon
docker run -ti -v /var/run/docker.sock:/var/run/docker.sock --privileged --rm --name docker-host docker:18.06.1-ce
# Runs a helper container that can call Docker commands.
# The socket mount means commands go to the host daemon (not a nested daemon).

note: `-v /var/run/docker.sock:...` mounts the host’s Docker API socket so the container talks to the host daemon (not a nested engine)—i.e. “Docker in Docker” via the host.
/ # cat /etc/issue
Welcome to Alpine Linux 3.8
Kernel \r on an \m (\l)

# from my terminal and not docker shell
# run stock alpine container
docker run --rm -dit --name my-alpine alpine:3.10 sh
# Starts a lightweight Alpine container in the background.
# `--rm` auto-cleans it up when it stops.

# export running container's file system
docker export -o dockercontainer.tar my-alpine
# Exports the container filesystem into a tar archive.
# This gives you a raw rootfs snapshot.

# make container-root directory, export contents of container into it
mkdir container-root
tar xf dockercontainer.tar -C container-root/
# Creates a local root filesystem directory.
# Extracted files become the base for manual container-like isolation.

# make a contained user, mount in name spaces
unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot $PWD/container-root ash # this also does chroot for us
# Enters new namespaces + chroot with root mapped inside that namespace.
# This simulates core container isolation primitives manually.
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp
# Mounts pseudo-filesystems expected by many Linux tools.
# Without these mounts, process/system info and temp behavior are incomplete.

# here's where you'd do all the cgroup rules making with the settings you wanted to

```
# 10 Docker Images with Docker.ts

Much easier than doing it by hand: Docker wraps the namespace/cgroup/chroot workflow into one CLI.

```bash
# open an interactive shell in Alpine
docker run --interactive --tty alpine:3.10
# short form:
docker run -it alpine:3.10
# `run` creates and starts a container from the image.
# `-it` keeps stdin open and gives you a TTY so you get an interactive shell.

# no interactive flags: container starts, does default command, then exits
docker run alpine:3.10
# If there is no long-running process, it stops immediately after command completion.

# run an explicit command in Alpine
docker run alpine:3.10 ls
# Executes `ls` inside the container, prints output, then container exits.

# same idea using Ubuntu image
docker run ubuntu:bionic ls
# Command at the end is executed inside the container as PID 1.

# run detached in background
docker run --detach -it ubuntu:bionic
# short form:
docker run -dit ubuntu:bionic
# Returns container ID and keeps it running without attaching your terminal.

# list running containers
docker ps
# Shows active containers, IDs, names, image, uptime, and exposed ports.

# attach to a running container by ID or name
docker attach <ID or name>
# Reconnects your terminal to the container's primary process/stdout.

# kill one or more containers
docker kill <IDs or names of containers>
# Sends SIGKILL by default, immediately stopping those containers.

# kill all running containers
docker kill $(docker ps -q)
# `docker ps -q` outputs only IDs; command substitution passes them to `docker kill`.

# run with a stable custom name
docker run -dit --name my-ubuntu ubuntu:bionic
docker kill my-ubuntu
# Naming containers makes follow-up commands easier than using random IDs.

# remove stopped container metadata to free the name
docker rm my-ubuntu
# or clean all stopped containers:
docker container prune
# Docker keeps stopped containers until removed; prune cleans them in bulk.

# auto-remove container after it stops
docker run --rm -dit --name my-ubuntu ubuntu:bionic
docker kill my-ubuntu
# `--rm` deletes the container once it exits, avoiding stale container records.
```

# 11 Node.js on Docker.ts

Need Node.js in the container? Use the Node image instead of plain Ubuntu.

```bash
# start Node 12 on Debian Stretch
docker run -it node:12-stretch
# `node:12-stretch` = Node.js v12 + Debian Stretch base image.
# By default this image starts the `node` command, so you land in the Node REPL.

# override default command and open a shell instead
docker run -it node:12-stretch bash
# Anything after image name replaces the image default command.
# Here we run `bash` so we can inspect the container environment directly.

# check distro identity from inside different images
docker run ubuntu:bionic cat /etc/issue
docker run node:12-stretch cat /etc/issue
# `/etc/issue` prints distro/version info on most Linux images.
# This is a quick way to confirm what base OS an image is actually using.
```

# 12 Tags.ts

Tags let you choose *which version* of an image to run instead of always taking whatever is newest.

```bash
# implicit latest tag
docker run -it node
# equivalent explicit form
docker run -it node:latest
# Omitting a tag defaults to `:latest`.
# Good for quick experiments, risky for reproducible builds.

# pin to a legacy Node version
docker run -it node:8 bash
# Tags let you match runtime versions expected by older apps.
# Verify with `node --version` inside the shell.

# same Node major, different base distro
docker run node:12-alpine cat /etc/issue
# `node:12-alpine` swaps Debian/Ubuntu base for Alpine Linux.
# This is useful to compare footprint and base-OS behavior quickly.
```

Alpine is tiny (often single-digit MB images) and minimal by design, while Debian/Ubuntu images are larger but more convenient out of the box. Smaller images usually pull faster, cost less in storage/transfer, and reduce attack surface by shipping fewer unused tools.

Practical pattern: keep a feature-rich **dev image** (debuggers/tools included) and a minimal **prod image** (only what runtime needs). That gives a smoother developer experience without bloating production containers.

# 13 Docker CLI.ts

Quick tour of useful Docker CLI commands beyond `run`.

```bash
# pre-fetch image to local cache
docker pull jturpin/hollywood
docker run -it jturpin/hollywood hollywood
# `pull` downloads ahead of time so later `run` starts faster.
# `run` uses cached image layers when already present.

# upload an image to current registry (after tagging/login)
docker push <image[:tag]>
# Publishes your built image to Docker Hub or another registry.

# detailed metadata (image or container)
docker inspect node
# Dumps JSON with config, env, entrypoint, networking, mounts, and more.

# pause and resume a running container
docker run -dit jturpin/hollywood hollywood
docker ps
docker pause <ID or name>
docker ps
docker unpause <ID or name>
docker ps
docker kill <ID or name>
# `pause` freezes processes (cgroup freezer), `unpause` resumes them.

# run a command inside an already-running container
docker run -dit jturpin/hollywood hollywood
docker ps
docker exec <ID or name> ps aux
# `exec` is for entering/inspecting an existing container; it does not create a new one.

# image/container tar workflows
docker export -o container.tar <container>
docker import container.tar <new-image-name>:<tag>
# `export` writes a container filesystem tar; `import` turns tar into an image.

# show image layer history
docker history node
# Useful for understanding image size growth and layer composition.

# host/daemon diagnostics
docker info
# Shows Docker engine version, storage driver, CPUs/RAM, and runtime details.

# list processes in a container
docker run -d mongo
docker top <ID or name>
# Fast process view for container internals without shelling in.

# cleanup containers/images
docker ps --all
docker rm <ID or name>
docker rmi mongo
# `rm` removes stopped containers; `rmi` removes images from local disk.

# read container stdout/stderr logs
docker run -d mongo
docker logs <ID or name>
# Great for debugging startup failures or checking service output.

# restart a running container
docker restart <ID or name>
# Stops then starts the same container with existing config.

# search image names on Docker Hub/default registry
docker search python
docker search node
# Quick discovery of image families and official/community variants.
```

# 14 Dockerfiles Preamble.ts

Running containers is the main day-to-day skill, but Dockerfiles are how you package your own runtime repeatably.

Core mindset: containers should be **disposable**. Build them so recreating from scratch is normal, fast, and safe.

Each Dockerfile line is an instruction that creates a new image layer. You are incrementally transforming a base image into your app image.

```Dockerfile
# The most basic Dockerfile-based container
FROM node:12-stretch
CMD ["node", "-e", "console.log(\"hi lol\")"]
```

`FROM` picks the starting base image. `CMD` sets the default command when someone runs the container (last `CMD` wins if multiple are present).

Preferred `CMD` form is JSON array (exec form), which runs directly without shell parsing and is generally more predictable.

```bash
# build from current directory (where Dockerfile exists)
docker build .
# Builds an image from Dockerfile and build context.
# Output shows intermediate layer/image IDs per instruction.

# run built image by image ID/hash
docker run <ID>
# Useful quick test, but IDs are hard to remember.

# tag image with a readable name
docker build . --tag my-node-app
# short form:
docker build -t my-node-app .
docker run my-node-app
# Tag makes local image references human-friendly.

# semantic/versioned tags
docker build -t my-node-app:1 .
docker run my-node-app:1
# Tags let you keep multiple builds and choose exactly which one to run.

# after changing Dockerfile output (e.g., hi lol -> wat)
docker build -t my-node-app:2 .
docker run my-node-app:2
docker run my-node-app:1
# Demonstrates immutable versioning: old tag and new tag can coexist.
```

Important layering idea: your image includes your instructions **plus** all layers from its base image lineage (`node` -> Debian stack). This reuse is why Docker builds are so composable and fast when caches hit.

# 15 Build a Node.js App.ts

Now move from a one-liner CMD to a real app file and package it into the image.

```javascript
const http = require("http");

http
  .createServer(function(request, response) {
    console.log("request received");
    response.end("omg hi", "utf-8");
  })
  .listen(3000);
console.log("server started");
```

This is a minimal HTTP server: listens on port `3000`, logs requests, and returns `"omg hi"`.

```bash
# run locally first (outside Docker) to validate behavior
node index.js
# Then open http://localhost:3000 from host to verify response.
```

### First Dockerfile version (copy file + run it)

```Dockerfile
FROM node:12-stretch
COPY index.js index.js
CMD ["node", "index.js"]
```

`COPY <src> <dest>` copies from host build context into image filesystem.

```bash
docker build -t my-node-app .
docker run my-node-app
# App is running in container, but not yet reachable from host browser.
```

To access it from host, publish the port and use an init process for cleaner signal handling:

```bash
docker run --init --publish 3000:3000 my-node-app
# short publish flag:
docker run --init -p 3000:3000 my-node-app
# Host:container mapping means host port 3000 forwards to container port 3000.
# Example: `-p 8000:3000` => open localhost:8000 on host.
```

### Safer Dockerfile (non-root user + home dir)

```Dockerfile
FROM node:12-stretch
USER node
COPY --chown=node:node index.js /home/node/code/index.js
CMD ["node", "/home/node/code/index.js"]
```

Running as non-root reduces blast radius if app/runtime is compromised.

`--chown=user:group` avoids permission issues by making copied files owned by the runtime user.

### Cleaner Dockerfile (use WORKDIR)

```Dockerfile
FROM node:12-stretch
USER node
WORKDIR /home/node/code
COPY --chown=node:node index.js .
CMD ["node", "index.js"]
```

`WORKDIR` acts like `cd` for following instructions and creates the directory if needed.

### COPY vs ADD (quick rule)

Use `COPY` by default. Use `ADD` only when you explicitly need its extras (remote URL fetch or automatic tar extraction).

# 16 Run a Node.js App.ts
# For the basic app from section 15, build + run with published port:
#
# docker build -t my-node-app .
# docker run --init -p 3000:3000 my-node-app
#
# If localhost does not respond, verify the app listens on `0.0.0.0` inside the container.

# 17 Add Dependencies to a Node.js App.ts

### A more complicated Node.js app (Hapi + logging)

```javascript
// more-or-less the example code from the hapi-pino repo
const hapi = require("@hapi/hapi");

async function start() {
  const server = hapi.server({
    host: "0.0.0.0",
    port: process.env.PORT || 3000
  });

  server.route({
    method: "GET",
    path: "/",
    handler() {
      return { success: true };
    }
  });

  await server.register({
    plugin: require("hapi-pino"),
    options: {
      prettyPrint: true
    }
  });

  await server.start();
  return server;
}

start().catch(err => {
  console.log(err);
  process.exit(1);
});
```

This adds real dependencies and a structured server, so image build now needs an install step.

```bash
npm init -y
npm install @hapi/hapi hapi-pino
node index.js
# Local run confirms app and dependencies work before containerizing.
```

### Dockerfile with dependency install

```Dockerfile
FROM node:12-stretch
USER node
WORKDIR /home/node/code
COPY --chown=node:node . .
RUN npm ci
CMD ["node", "index.js"]
```

`RUN` executes at image build time; `npm ci` installs exactly from lockfile for reproducible builds.

### Add `.dockerignore` to avoid copying junk

```gitignore
node_modules/
.git/
```

Avoid sending local `node_modules` and git metadata as build context.

### Permission fix for WORKDIR + non-root user

If build fails with permissions, create the working directory as `node` before switching into it:

```Dockerfile
FROM node:12-stretch
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --chown=node:node . .
RUN npm ci
CMD ["node", "index.js"]
```

`WORKDIR` creation can be root-owned in some setups; pre-creating it as runtime user avoids write/install issues.

Network gotcha: bind server host to `0.0.0.0` (not `localhost`) so the container port is reachable through Docker publish mapping.

# 18 EXPOSE.ts

`EXPOSE <port>` often confuses people: it does **not** publish a port to the host by itself.

You still need runtime publish flags (usually `-p host:container`) to make service traffic reachable from outside the container.

```Dockerfile
EXPOSE 3000
```

Think of `EXPOSE` mainly as image metadata/documentation ("this app listens on this port"), not as an access control or host mapping mechanism.

```bash
# explicit and predictable host mapping
docker run -p 3000:3000 my-node-app
# Host 3000 forwards to container 3000.

# publish all EXPOSEd ports to random host ports
docker run -P my-node-app
docker ps
# `-P` maps each EXPOSEd container port to an ephemeral host port.
# `docker ps` shows the chosen mapping (example: 0.0.0.0:32769->3000/tcp).
```

Practical preference: use explicit `-p` in most workflows so port mapping is stable and easy to reason about.

# 19 Layers.ts

Docker builds are layer-based and cache-aware. If earlier instructions are unchanged, Docker reuses cached layers and resumes from the first changed instruction.

Typical case: edit `index.js` and rebuild. `FROM`, `USER`, `RUN mkdir`, and `WORKDIR` stay cached, but `COPY . .` changes, so Docker reruns that layer and everything after it.

The slowest step is usually dependency install (`RUN npm ci`) because it often hits the network. If app code changes but dependency manifests do not, we can avoid reinstalling dependencies by ordering layers better.

```Dockerfile
FROM node:12-stretch
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code

# copy only dependency manifests first
COPY --chown=node:node package-lock.json package.json ./
RUN npm ci

# copy application source after dependencies are installed
COPY --chown=node:node . .

CMD ["node", "index.js"]
```

Why this is faster:
- If only source files change, Docker reuses cached `npm ci` layer.
- `npm ci` reruns only when `package.json` or `package-lock.json` changes.

This pattern generalizes to other ecosystems too: `pip`, `apt`, `cargo`, `bundler`, and other expensive build/install steps should be placed after the smallest possible cache key inputs.

# 20 Docker Ignore.ts

Docker uses a `.dockerignore` file to exclude files and directories from build context uploads, much like `.gitignore` for Git.

**Shot notes:**
- Keeps images smaller by not sending unnecessary files (test data, docs, node_modules, etc)
- Improves build speed (less data, faster context send)
- Reduces risk of secrets accidentally leaking into images
- Syntax matches `.gitignore`: one pattern per line, directories/files to ignore

Example `.dockerignore`:
```
node_modules
.git
*.log
Dockerfile
.dockerignore
test/
```

Pro tip: Always review your `.dockerignore`. Accidentally missing it means uploading your entire project (including `node_modules` and `.git`) on every build!

# 21 Alpine Linux.ts

You can ship the previous Node image as-is, but switching to Alpine often makes images smaller, cheaper to move/store, and smaller in attack surface.

```Dockerfile
FROM node:12-alpine
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --chown=node:node package-lock.json package.json ./
RUN npm ci
COPY --chown=node:node . .
CMD ["node", "index.js"]
```

This is often a drop-in `FROM` change with major size savings (course example: roughly `913MB` -> `86MB`).

Why smaller helps:
- Faster pulls/pushes and deployments.
- Lower registry/storage/network costs.
- Fewer unused tools/packages means fewer potential vulnerabilities.

Alpine context:
- Alpine is a minimal distro (built on BusyBox tooling) designed for small containers.
- `node:12-alpine` is much smaller than full Debian/Ubuntu-flavored Node images.

When to choose Alpine (practical rule):
- **Great for production/end-destination images** where minimal footprint matters most.
- **Less convenient for development-heavy images** because common debugging/build tools are often missing.
- For intermediate/developer workflows (dev containers, build stages), Debian/Ubuntu images can be easier to work with.

# 22 Alpine Node.js Container.ts

Exercise: build your own Node.js-on-Alpine image from `alpine` base (for learning).  
Production recommendation: prefer official Node images for security updates and maintenance.

### Minimal custom Node image on Alpine

```Dockerfile
FROM alpine:3.10
RUN apk add --update nodejs npm
```

`apk` is Alpine's package manager. This installs Node.js and npm from Alpine repos.

If you use `alpine:latest` and hit compatibility issues, pin to `alpine:3.10` for this course flow.

If runtime errors mention modern JS syntax unsupported by Node version (e.g. `Unexpected token =`), try:

```Dockerfile
RUN apk add --update nodejs-current npm
```

```bash
docker build -t my-node -f my-node.Dockerfile .
docker run -it my-node
# inside container:
node -v
npm -v
```

`-f` chooses a non-default Dockerfile name; otherwise Docker expects `Dockerfile`.

Alpine shell note: default shell is typically `sh`/`ash` (not bash).

### Add a non-root runtime user

```Dockerfile
FROM alpine:3.10
RUN apk add --update nodejs npm
RUN addgroup -S node && adduser -S node -G node
USER node
```

This mirrors the official Node image pattern: create `node` group/user and drop root privileges.

### Full app Dockerfile on plain Alpine

```Dockerfile
FROM alpine:3.10
RUN apk add --update nodejs npm
RUN addgroup -S node && adduser -S node -G node
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --chown=node:node package-lock.json package.json ./
RUN npm ci
COPY --chown=node:node . .
CMD ["node", "index.js"]
```

Course result: custom image can be smaller than `node:12-alpine`, but official images are usually safer defaults because they include curated fixes and maintenance choices that are easy to miss in hand-rolled bases.

# 23 Multi-Stage Builds.ts

Multi-stage builds let you use one image to **build** artifacts and a different (smaller) image to **run** them.

Great fit when build-time tooling is heavy but runtime needs are small (TypeScript compilers, C/C++ toolchains, Rust, Sass, etc.).

### Example: keep npm in build stage, drop it from runtime stage

Create `multi-node.Dockerfile`:

```Dockerfile
# build stage
FROM node:12-stretch
WORKDIR /build
COPY package-lock.json package.json ./
RUN npm ci
COPY . .

# runtime stage
FROM alpine:3.10
RUN apk add --update nodejs
RUN addgroup -S node && adduser -S node -G node
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --from=0 --chown=node:node /build .
CMD ["node", "index.js"]
```

Key ideas:
- Multiple `FROM` instructions = multiple stages.
- Final stage is the shipped image.
- `COPY --from=0` copies files from first stage (`0`-indexed).
- Runtime stage omits npm, keeping only what is needed to execute Node app.

```bash
docker build -t multi-node -f multi-node.Dockerfile .
docker run -p 3000:3000 multi-node
```

Result in the course flow: image drops further (about `39MB`) versus single-stage custom Alpine (`56MB`), `node:12-alpine` (`86MB`), and full `node:latest` style base (`~913MB`).

Practical tradeoff: multi-stage is powerful, but every custom layer adds maintenance. Big reductions are usually worth it (e.g. `913MB` -> `86MB`), while small final optimizations may not justify complexity for every project.

# 24 Static Assets Project Exercise.ts

Project: containerize a React + TypeScript static app with a multi-stage build.

Goal:
- Build assets in a Node image.
- Serve built files from an NGINX image.
- Copy only production artifacts (`build/`) into runtime image.

Bootstrap a sample app:

```bash
npx --ignore-existing create-react-app static-assets-project --template typescript --use-npm
```

If `create-react-app` is globally installed and causes issues, uninstall global install and use `npx` flow above.

Optional Sass step:

```bash
cd static-assets-project
npm install node-sass
```

Rename `.css` files to `.scss` and update imports in `App.tsx` and `index.tsx`.

Local sanity checks before Dockerizing:

```bash
npm run start
npm run build
```

`start` verifies dev server; `build` confirms production artifact generation.

Exercise requirement:
- Create a multi-stage Dockerfile.
- Use Node stage for `npm ci` + `npm run build`.
- Use `nginx:latest` (or `nginx:alpine`) as runtime.
- Copy `/app/build` to `/usr/share/nginx/html`.
- Run with host port mapping like `8080:80` (NGINX listens on `80`).

# 25 Static Assets Project Solution.ts

Reference solution:

```Dockerfile
FROM node:latest
WORKDIR /app
COPY . .
RUN npm ci && npm run build

# you could totally use nginx:alpine here too
FROM nginx:latest
COPY --from=0 /app/build /usr/share/nginx/html
```

Why this works:
- First stage installs dependencies and builds static assets.
- Final stage contains only NGINX + built files (no source/build tooling).
- NGINX default CMD serves `/usr/share/nginx/html` automatically.

```bash
docker build -t static-app .
docker run -p 8080:80 static-app
```

Open `http://localhost:8080` to verify.

Practical note: for production, pin explicit image versions/tags instead of `latest` for reproducibility.

# 26 Bind Mounts.ts

Default container best practice is still ephemeral/stateless images (easy to recreate, no snowflake servers).

Bind mounts are the escape hatch when a container needs direct access to host files at runtime.

Use case: quickly serve already-built local static files with stock NGINX, without creating a custom image.

```bash
# from CRA project root (after `npm run build`)
docker run --mount type=bind,source="$(pwd)"/build,target=/usr/share/nginx/html -p 8080:80 nginx
```

Mount flag breakdown:
- `--mount`: declare a mount explicitly.
- `type=bind`: mount an existing host path.
- `source=...`: absolute host path to expose (use `$(pwd)` so path is absolute).
- `target=...`: where files appear inside container.

Why this works with NGINX: default NGINX serves files from `/usr/share/nginx/html`, so binding your local `build/` there serves your app immediately.

You can define multiple mounts in one `docker run` (and mix bind + volume). Example pattern: mount app files plus custom config file like `/etc/nginx/nginx.conf`.

Tradeoff:
- **Good for local testing and fast iteration.**
- **Less ideal for shipping production artifacts** because code and runtime must be deployed together; baked images are usually simpler and more reproducible.

# 27 Volumes.ts

Bind mounts share host-managed files with containers. Volumes are Docker-managed storage designed for persistent container data across runs.

Quick rule:
- Use **bind mounts** when you intentionally need host files (source code, local config, dev workflows).
- Use **volumes** for container-owned state (databases, app data, runtime-generated files).

Key distinction:
- Bind mount data lives in normal host paths.
- Volume data lives in Docker-managed storage (discoverable, but managed via Docker tooling).

### Example: persistent incrementing counter

Create a tiny Node project:

```bash
mkdir docker-volume
cd docker-volume
touch index.js Dockerfile
```

`index.js`:

```javascript
const fs = require("fs").promises;
const path = require("path");

const dataPath = path.join(process.env.DATA_PATH || "./data.txt");

const writeTo = data => {
  fs.writeFile(dataPath, data.toString()).catch(console.error);
};

fs.readFile(dataPath)
  .then(buffer => {
    const data = buffer.toString();
    console.log(data);
    writeTo(+data + 1);
  })
  .catch(() => {
    console.log("file not found, writing '0' to a new file");
    writeTo(0);
  });
```

This app reads a number from file, prints it, increments it, and writes it back.

`Dockerfile`:

```Dockerfile
FROM node:12-alpine
COPY --chown=node:node . /src
WORKDIR /src
CMD ["node", "index.js"]
```

Build + run without volume:

```bash
docker build --tag=incrementor .
docker run incrementor
```

Without persistent mount, each fresh container run starts over from image state.

Run with named volume + explicit data path:

```bash
docker run --env DATA_PATH=/data/num.txt --mount type=volume,src=incrementor-data,target=/data incrementor
```

Now repeated runs persist counter data in `incrementor-data`.

Notes:
- Named volumes are easier to reuse/manage than anonymous volumes.
- Anonymous volumes still persist, but are harder to target reliably later.

Other mount types (brief):
- `tmpfs` (Linux): in-memory filesystem, useful for sensitive ephemeral data.
- `npipe` (Windows): named pipe support for Windows container integrations.

Practical guidance: prefer volumes for persistent app state, bind mounts for host-integration workflows.

# 28 Containers & Dev Environment.ts

Containers are not only for packaging production apps; they are also great for making local dev environments reproducible.

Pain point this solves: onboarding to unfamiliar stacks (Ruby, Go, etc.) often means long, stale setup docs and local dependency drift.

Container-first dev setup pattern:
- Put toolchain/runtime in container image.
- Bind mount local source into container.
- Edit on host, run in container.

Result: everyone gets the same environment without manually installing language runtimes and system deps.

### Example: run a Hugo project without installing Go locally

```bash
git clone https://github.com/btholt/hugo-example.git
cd hugo-example/

# equivalent mount shorthand: -v "$PWD":/src
docker run --rm -it --mount type=bind,source="$(pwd)",target=/src -p 1313:1313 -u hugo jguyomard/hugo-builder:0.55 hugo server -w --bind=0.0.0.0
```

Flag and parameter breakdown:
- `docker run`: start a new container from an image.
- `--rm`: automatically remove the container after it exits.
- `-it`: interactive mode (`-i` keeps STDIN open, `-t` allocates a TTY).
- `--mount type=bind,source="$(pwd)",target=/src`: bind mount current host directory into `/src` in the container.
- `-p 1313:1313`: map host port `1313` to container port `1313`.
- `-u hugo`: run the container process as user `hugo`.
- `jguyomard/hugo-builder:0.55`: image and tag to run.
- `hugo server`: command executed inside the container.
- `-w`: watch files and rebuild on changes.
- `--bind=0.0.0.0`: listen on all container interfaces so the host can access it.

Why this is useful:
- Zero local Go/Hugo install required.
- Source stays on host for normal editor workflow.
- Container can be thrown away and recreated anytime.

### Node.js caveat: native dependencies

When host OS and container OS differ, native Node modules can mismatch ABI/platform (for example `node-sass` style dependencies).

Two practical options:
- **Manual but reliable:** start dev container, then run `npm install` inside container environment.
- **Automated but noisy:** prepend `npm install &&` to dev startup command so deps install on each run.

The first is usually faster for repeated inner-loop work; the second trades startup time for less manual intervention.

# 29 Dev Containers with Visual Studio Code.ts

VS Code Dev Containers let you codify editor + runtime setup so teammates open the repo and get a consistent environment immediately.

Install extension: **Remote - Containers** (or current Dev Containers extension naming in VS Code marketplace).

Create `.devcontainer/` in your project with two files.

`.devcontainer/Dockerfile`:

```Dockerfile
FROM node:12-stretch
RUN npm install -g eslint prettier
```

This image defines tooling for development only (not production runtime).

`.devcontainer/devcontainer.json`:

```json
{
  "name": "Frontend Masters Sample",
  "dockerFile": "Dockerfile",
  "appPort": [3000],
  "runArgs": ["-u", "node"],
  "settings": {
    "workbench.colorTheme": "Night Owl",
    "terminal.integrated.shell.linux": "/bin/bash"
  },
  "postCreateCommand": "npm install",
  "extensions": [
    "sdras.night-owl",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode"
  ]
}
```

What this config does:
- Uses your dev Dockerfile as editor runtime.
- Exposes app port for local preview.
- Runs container as non-root user.
- Applies baseline editor settings and extensions.
- Installs project dependencies on first container creation.

How to open in container:
- Reopen project and accept "Reopen in Container" prompt.
- Or use the bottom-left remote button (`><`) and choose reopen in dev container.

WSL note: if reopen-in-container flow fails from WSL context, open workspace from Windows-side VS Code first, then reopen in container.

Practical team benefits:
- Onboarding gets simpler (no manual runtime setup for each developer).
- Linters/formatters/extensions are consistent across machines.
- You can keep separate Dockerfiles for **dev** and **prod** when goals differ.

Even non-VS Code users can still run the same dev container image directly with Docker commands; the devcontainer setup is additive, not exclusive.

# 30 Networks & Docker MongoDB Container.ts

This is a practical networking skim, not a deep networking theory dive. Goal: understand enough manual Docker networking to appreciate what Compose/Kubernetes automate.

Why networking matters here: app container and database container run separately, so they need a shared network and stable addressing.

List Docker networks:

```bash
docker network ls
```

Typical defaults:
- `bridge` (default bridge network)
- `host` (host networking)
- `none` (no networking)

Best practice for app stacks: create a dedicated bridge network instead of reusing the default one.

```bash
docker network create --driver=bridge app-net
```

Start MongoDB on that network:

```bash
docker run -d --network=app-net -p 27017:27017 --name=db --rm mongo:3
```

Flag notes:
- `--network=app-net`: joins custom bridge network.
- `--name=db`: gives a predictable DNS hostname (`db`) on that network.
- `--rm`: auto-removes stopped container metadata so name is reusable.
- `-p 27017:27017`: optional host exposure for local inspection/tools.

Quick connectivity check using another Mongo image (client connecting to DB container by name):

```bash
docker run -it --network=app-net --rm mongo:3 mongo --host db
```

This confirms container-to-container communication over Docker DNS/bridge networking.

# 31 Networks & Docker Client Side Container.ts

### Connect Node app container to MongoDB container

Use env-configured connection string so app works both locally and in containers:

```javascript
// more-or-less the example code from the hapi-pino repo
const hapi = require("@hapi/hapi");
const { MongoClient } = require("mongodb");
const url = process.env.MONGO_CONNECTION_STRING || "mongodb://localhost:27017";
const dbName = "dockerApp";
const collectionName = "count";

async function start() {
  const client = await MongoClient.connect(url);
  const db = client.db(dbName);
  const collection = db.collection(collectionName);

  const server = hapi.server({
    host: "0.0.0.0",
    port: process.env.PORT || 3000
  });

  server.route({
    method: "GET",
    path: "/",
    async handler() {
      const count = await collection.count();
      return { success: true, count };
    }
  });

  server.route({
    method: "GET",
    path: "/add",
    async handler() {
      const res = await collection.insertOne({});
      return { inserted: res.insertedCount };
    }
  });

  await server.register({
    plugin: require("hapi-pino"),
    options: {
      prettyPrint: true
    }
  });

  await server.start();
  return server;
}

start().catch(err => {
  console.log(err);
  process.exit(1);
});
```

Install MongoDB driver and run app container on same network:

```bash
npm install mongodb@3.3
docker build --tag=my-app-with-mongo .
docker run -p 3000:3000 --network=app-net --env MONGO_CONNECTION_STRING=mongodb://db:27017 my-app-with-mongo
```

Behavior:
- `GET /add` inserts one document.
- `GET /` returns current count.

Key takeaway: containers discover each other by container name on the same custom bridge network (`db` in this example).

Data durability note: if DB container is deleted without persistent storage, data is lost. Use volumes and multi-node DB setups for real durability.

# 32 Docker Compose.ts

Docker Compose is one of the highest-leverage Docker tools for local multi-container development.

Instead of manually coordinating several `docker run` commands (app + DB + cache + etc.), Compose captures the stack in one YAML file and boots it with one command.

Create `docker-compose.yml` at project root:

```yaml
version: "3"
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/home/node/code
      - /home/node/code/node_modules
    links:
      - db
    environment:
      MONGO_CONNECTION_STRING: mongodb://db:27017
  db:
    image: mongo:3
```

How this maps to earlier CLI workflow:
- `services`: each container in your app stack.
- `web.build: .`: build app image from local Dockerfile.
- `ports`: host-to-container port mapping.
- `volumes`: mount source code for live local editing.
- `environment`: inject runtime env vars (DB connection string).
- `links`: legacy-style service wiring; in modern Compose, service DNS usually works on default network without explicit links.

Why the second `volumes` entry helps Node projects:
- `- /home/node/code/node_modules` keeps container-built `node_modules` from being overwritten by host files.
- Prevents host/container OS mismatch issues for native dependencies.

Bring stack up:

```bash
docker-compose up
```

Compose is also useful in CI pipelines when integration tests need several dependent services running together.

# 33 Docker Compose & nodemon.ts

To improve local iteration speed, make the app container auto-restart on file changes with `nodemon`.

Update app Dockerfile:

```Dockerfile
FROM node:latest
RUN npm i -g nodemon
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --chown=node:node package-lock.json package.json ./
RUN npm ci
COPY --chown=node:node . .
CMD ["nodemon", "index.js"]
```

With code bind-mounted through Compose, saving local files triggers server restart inside container.

Scaling note:

```bash
docker-compose up --scale web=10
```

This can run multiple `web` containers, but direct host-port binding (`3000:3000`) conflicts for replicas. In practice you add a reverse proxy/load balancer or move to an orchestrator (like Kubernetes) for real multi-instance routing.

# 34 Kubernetes Fundamentals.ts

Containers are the "simpler" part; Kubernetes is the hard part. If Kubernetes feels difficult, that is normal.

Abbreviation note: Kubernetes is often written as `k8s` (`k` + 8 letters + `s`).

Why Kubernetes exists:
- Containers solve packaging/runtime consistency.
- Kubernetes solves orchestration of many containers across many hosts.
- You generally need container fluency first, then Kubernetes.

Use-case framing:
- Containers alone are useful for many workflows (apps, ML, dev envs, experiments).
- Kubernetes becomes useful when you need cluster-scale scheduling, resiliency, and operations automation.

Core concepts (high-level):
- **Control plane (master)**: coordinates the cluster and desired/current state reconciliation.
- **Node**: worker machine where workloads actually run.
- **Pod**: smallest deployable unit; one or more tightly coupled containers scheduled together.
- **Service**: stable network identity/load-balancing front for changing pod instances.
- **Deployment**: desired-state declaration for rolling out and maintaining pod replicas.

Quick intuition:
- Pod IPs can change as replicas scale/restart.
- Services provide stable discovery so workloads do not depend on ephemeral pod IPs.
- One-container/one-pod is common for simple app services.

Platform caveat from course context:
- Local Kubernetes on WSL can be rough in some setups.
- If local setup is blocking, observe the flow first and circle back.

# 35 Kubernetes & kubectl.ts

`kubectl` is the primary CLI for interacting with any Kubernetes cluster (local or cloud).

Local cluster choices for learning:
- Docker Desktop Kubernetes (easier to start).
- `minikube` (more explicit local-cluster tooling and flexibility).

You can have multiple cluster contexts and switch between them:

```bash
kubectl config use-context minikube
kubectl config use-context docker-desktop
# short form:
kubectl config use minikube
```

If using minikube, start cluster first:

```bash
minikube start
```

Basic verification commands:

```bash
kubectl cluster-info
kubectl get nodes
```

`cluster-info` confirms API/control-plane endpoints, and `get nodes` confirms worker/node readiness.

Practical path: start with a minimal hello-world deployment/service, then iterate into scaling, rolling updates, and observability.

# 36 Kompose.ts

Kompose helps bootstrap Kubernetes from a `docker-compose.yml`, which is often easier than writing raw Kubernetes YAML from scratch.

Install Kompose for your platform, then adapt Compose config for conversion/runtime expectations.

Updated `docker-compose.yml` for Kompose:

```yaml
version: "3"
services:
  web:
    image: btholt/node-app # change build to image
    ports:
      - "3000:3000"
    links:
      - db
    labels:
      kompose.service.type: LoadBalancer # need this label for Kubernetes
    environment:
      MONGO_CONNECTION_STRING: mongodb://db:27017
  db:
    image: mongo:3
    ports:
      - "27017" # explicitly expose the port
```

Notes:
- Kompose commonly expects image-based services, so push image to registry if not already available.
- `kompose.service.type: LoadBalancer` marks service for external exposure in generated manifests.
- Mongo port is declared explicitly so generated K8s service metadata is complete.

If using your own image:
- Keep `build: .`
- Use image tag like `<your-dockerhub-user>/node-app`
- Run `docker login` and push image before deployment

Compatibility hack from course flow:

```bash
kubectl proxy --port=8080
```

Keep that running, then in another terminal:

```bash
kompose up
kubectl get all
```

If everything is healthy, app should be reachable on `localhost:3000`.

# 37 Multiple Containers with Kompose.ts

### Scale and operate generated resources

Scale web deployment:

```bash
kubectl scale --replicas=5 deployment/web
kubectl get all
```

Scale back down if needed:

```bash
kubectl scale --replicas=1 deployment/web
```

Kubernetes handles replica reconciliation and routing across healthy pods for the service.

Cleanup all resources created in this namespace:

```bash
kubectl delete all --all
```

Generate Kubernetes YAML files (instead of directly applying):

```bash
kompose convert
```

This outputs deployments/services manifests you can inspect, version, and customize.

Cloud note: `kubectl` workflow is portable across local and cloud clusters (AKS/EKS/GKE) by changing context, but managed clusters incur real cost if left running.

# 38 Buildah.ts

Buildah and Podman are OCI-focused, open-source alternatives in the container ecosystem.

Platform note:
- Easiest on Linux.
- Works in many WSL setups.
- macOS usually needs a Linux VM/container workaround.

High-level split:
- **Buildah**: build images.
- **Podman**: run/manage containers.

This separation is conceptually similar to "build tool vs runtime daemon."

### Run Buildah in a helper container (course-friendly path)

```bash
docker run -it --rm -p 3000:3000 --privileged --mount type=bind,source="$(pwd)",target=/src --mount type=volume,src=podman-data,target=/var/lib/containers tomkukral/buildah bash
```

What this gives you:
- Bind mount of project source at `/src`.
- Docker-managed volume for container/image storage.
- Privileged mode (needed for nested container tooling in this setup).
- Port forwarding for testing apps from nested runtime.

If installing natively (non-container path), ensure your distro setup includes:
- valid `/etc/containers/registries.conf`
- `runc` installed

### Build with Buildah using Dockerfile

```bash
buildah bud -f ./Dockerfile -t my-app-buildah .
# long form:
buildah build-using-dockerfile -f ./Dockerfile -t my-app-buildah .
```

Useful follow-up commands:

```bash
buildah images
buildah inspect my-app-buildah
```

You can also start from image and run commands interactively:

```bash
buildah from my-app-buildah
buildah run --net host my-app-buildah-working-container -- bash
```

This validates image build/run flow without using Docker for image creation.

# 39 Buildah & Docker.ts

### Run Buildah-built image with Podman

After building image with Buildah:

```bash
podman run --cgroup-manager cgroupfs -p 3000:3000 localhost/my-app-buildah
```

By default this runs in foreground; add `-d` to detach.

### Push Buildah image into Docker daemon

Run this outside the helper container (where Docker daemon is available):

```bash
buildah push localhost/my-app-buildah docker-daemon:my-app-buildah:latest
```

Then run image with Docker as usual:

```bash
docker run -it my-app-buildah bash
```

Why this is useful:
- Demonstrates OCI image portability across tooling.
- Lets you build with Buildah and run with Docker/Podman depending on environment needs.

# 40 Podman.ts

Podman can run the image you built with Buildah directly, which is a useful OCI-toolchain exercise.

Course note: this workflow is often demonstrated inside the Buildah helper container for convenience, even though many teams still run Docker in day-to-day workflows.

Run Buildah-built image with Podman:

```bash
podman run --cgroup-manager cgroupfs -p 3000:3000 localhost/my-app-buildah
```

By default it runs in foreground; add `-d` to run detached.

### Run Buildah image with Docker (interop)

To do this part, run outside the helper container where Docker daemon is available.

Export from Buildah local image store to Docker daemon:

```bash
buildah push localhost/my-app-buildah docker-daemon:my-app-buildah:latest
```

Then run using Docker:

```bash
docker run -it my-app-buildah bash
```

Concept reminder:
- Buildah/Podman primarily speak OCI image formats.
- Docker daemon can consume compatible image content via `docker-daemon:` push target.
- This demonstrates that container images are portable across multiple toolchains.

Practice idea: start your Node app from this image and connect it to MongoDB using the same Docker networking patterns from earlier sections.

# 41 Wrapping Up.ts

You made it. This course covers a lot of surface area, and getting through it gives you a practical foundation for modern container workflows.

## What you learned

- What containers are and why they are useful.
- Core Linux primitives behind containers: `chroot`, namespaces, and cgroups.
- Docker fundamentals: images, containers, Dockerfiles, networking, bind mounts, and volumes.
- Development workflows: reproducible dev containers and VS Code devcontainer integration.
- Multi-container orchestration basics with Docker Compose.
- Intro-level Kubernetes concepts (`pod`, `service`, `deployment`) and local tooling (`kubectl`, Kompose).
- OCI ecosystem awareness beyond Docker (Buildah + Podman interoperability).

## Immediately useful outcomes

- Build reproducible app images for local/dev/prod use.
- Create shareable development environments so onboarding is faster.
- Run app + database stacks locally with predictable networking.
- Use multi-stage builds and caching patterns for smaller/faster images.
- Apply container portability across different tooling stacks.

## Looking ahead

Containers continue to be core to cloud delivery across major platforms (Azure, AWS, GCP), including managed container and Kubernetes services.

As next steps, deepen one area at a time:
- Kubernetes operations (deployments, services, ingress, rollout strategy).
- CI/CD integration for container build/test/release pipelines.
- Security hardening (least privilege, image scanning, secrets management, supply-chain policies).

## Ecosystem notes

Other runtimes/orchestrators exist and may fit different constraints:
- Runtime/container ecosystem examples: LXC/LXD, rkt (historical/alternative contexts).
- Orchestration alternatives: Docker Swarm, Apache Mesos, HashiCorp Nomad.
- Host OS choices for container clusters: Ubuntu/Debian/Fedora, CoreOS-like offerings, RancherOS-style systems, and other specialized hosts.

The key takeaway: keep the fundamentals strong, and the specific tool choice becomes an implementation detail you can adapt over time.

