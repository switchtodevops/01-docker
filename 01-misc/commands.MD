📦 Version & System InfoShow Docker version informationBashdocker version
docker version -f json
Display system-wide informationBashdocker info
🚀 Container LifecycleCreate and run a new container from an imageBash# Syntax
docker run --name <CONTAINER-NAME> -p <HOST_PORT>:<CONTAINER_PORT> -d <IMAGE_NAME>:<TAG>

# Example
docker run --name myapp1 -p 8080:80 -d stacksimplify/mynginx:v1
List containersBashdocker ps      # List running containers
docker ps -a   # List all containers (including stopped)
docker ps -q   # List only numeric IDs
Start, Stop, and RestartBash# Stop a container
docker stop <CONTAINER-NAME>

# Start a stopped container
docker start <CONTAINER-NAME>

# Restart a container
docker restart <CONTAINER-NAME>
Pause and UnpauseBash# Pause processes
docker pause myapp1

# Unpause processes
docker unpause myapp1
Remove containersBashdocker rm <CONTAINER-NAME>
🛠 Interaction & TroubleshootingExecute a command in a running containerBash# Open an interactive shell
docker exec -it <CONTAINER-NAME> /bin/sh

# List files or check environment variables
docker exec -it myapp1 ls
docker exec -it myapp1 printenv
Monitoring & InspectionBash# Fetch the logs of a container
docker logs <CONTAINER-NAME>

# Display running processes of a container
docker top <CONTAINER-NAME>

# List port mappings
docker port <CONTAINER-NAME>
🖼 Image ManagementList and Remove ImagesBash# List all images
docker images
docker image ls

# List only image IDs
docker images ls -q

# Remove a specific image
docker rmi <IMAGE-ID>

# Remove all images
docker rmi $(docker image ls -q)
Build, Tag, and Registry OperationsCommandDescriptiondocker buildBuild an image from a Dockerfiledocker tagCreate a tag TARGET_IMAGE referring to SOURCE_IMAGEdocker pullDownload an image from a registrydocker pushUpload an image to a registrydocker loginAuthenticate to a registrydocker logoutLog out from a registry