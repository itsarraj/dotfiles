# Docker Cheatsheet

# INSTALLATION
## Docker Desktop is available for Mac, Linux and Windows
[Docker Desktop](https://docs.docker.com/desktop)
## View example projects that use Docker
[Awesome Compose](https://github.com/docker/awesome-compose)
## Check out our docs for information on using Docker
[Docker Docs](https://docs.docker.com)

# CLI cheatsheet for docker
docker run -it --name docker-host --rm --privileged ubuntu:bionic

# DETAILS OF: docker run -it --name docker-host --rm --privileged ubuntu:bionic

docker run                  # Command to create and start a new container

-it                        # (-i and -t) Enable interactive mode with a pseudo-TTY for shell/terminal use
    -i                     # Keep STDIN open even if not attached
    -t                     # Allocate a pseudo-TTY (makes it like a real terminal)

--name docker-host         # Assigns the name "docker-host" to the running container, 
                          # making it easier to reference by name instead of container ID.

--rm                      # Automatically remove the container when it exits.
                          # Useful for temporary containers that you don't want to keep.

--privileged              # Grants the container extended Linux kernel capabilities, 
                          # giving it full access to host devices and some host features.
                          # Required for containers that need to mount devices, change sysctl, etc.

ubuntu:bionic             # The image and tag to use for the container:
                          # 'ubuntu' is the image name, 'bionic' is the tag (Ubuntu 18.04 LTS).

# FULL ANNOTATED BREAKDOWN:
# docker run -it --name docker-host --rm --privileged ubuntu:bionic
#   |     |         |            |          |         |
#   |     |         |            |          |         +-- IMAGE:TAG to base container on
#   |     |         |            |          +------------ flag: full root-like privileges in container
#   |     |         |            +----------------------- flag: remove container after exit
#   |     |         +------------------------------------ flag: name for container
#   |     +---------------------------------------------- flags: interactive terminal
#   +---------------------------------------------------- command to create/run a container

# EXAMPLE USE CASE:
#   You want a temporary Ubuntu shell/host, need full privileges (for docker-in-docker, device mount, etc), and
#   want it to clean up automatically after exit.

# Replace ubuntu:bionic with another image/tag for different OS versions if needed.

# COMMON VARIANTS:
# docker run -it ubuntu         # Quick interactive shell, auto-generated name, keeps container after exit
# docker run --rm <image>       # Temporary container, auto-deletes after exit
# docker run --privileged ...   # Needed for some system-level actions in container

---

# Docker Images 
# Docker images are a lightweight, standalone, executable package
# of software that includes everything needed to run an application:
# code, runtime, system tools, system libraries and settings.

# IMAGE TYPES:
# Base images (e.g. ubuntu:bionic) - minimal OS environments
# Application images (e.g. node:12-stretch) - runtime + dependencies
# Custom images (built from Dockerfile) - app + runtime + dependencies

# IMAGE LAYERS:
# Each instruction in Dockerfile creates a new layer

docker build -t <image_name> . # Build an Image from a Dockerfile
docker build -t <image_name> . --no-cache # Build an Image from a Dockerfile without the cache
docker images # List local images
docker rmi <image_name> # Delete an Image
docker image prune # Remove all unused images




---

# Docker HUB
# Docker Hub is a service provided by Docker for finding and sharing
# container images with your team. Learn more and find images
# at [Docker Hub](https://hub.docker.com)

docker login -u <username> # Login into Docker
docker push <username>/<image_name> # Publish an image to Docker Hub
docker search <image_name> # Search Hub for an image
docker pull <image_name> # Pull an image from Docker Hub

---


# Docker General Commands
# Start the Docker daemon (platform-specific; `docker -d` is obsolete)
# Linux (systemd): sudo systemctl start docker
# Docker Desktop: starts the engine automatically
docker --help # Get help with Docker. Can also use --help on all subcommands
docker info # Display system-wide information

---

# Docker Containers

# A container is a runtime instance of a docker image. A container
# will always run the same, regardless of the infrastructure.
# Containers isolate software from its environment and ensure
# that it works uniformly despite differences for instance between
# development and staging.

docker run --name <container_name> <image_name> # Create and run a container from an image, with a custom name:
docker run -p <host_port>:<container_port> <image_name> # Run a container with and publish a container’s port(s) to the host.
docker run -d <image_name> # Run a container in the background
docker start|stop <container_name> (or <container-id>) # Start or stop an existing container
docker rm <container_name> # Remove a stopped container:
docker exec -it <container_name> sh # Open a shell inside a running container:
docker logs -f <container_name> # Fetch and follow the logs of a container:
docker inspect <container_name> (or <container_id>) # To inspect a running container:
docker ps # To list currently running containers:
docker ps --all # List all docker containers (running and stopped):
docker container stats # View resource usage stats


