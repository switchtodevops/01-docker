01 - Explain the the fields in the docker ps ? 
    - CONTAINER ID
    - IMAGE
    - COMMAND 
    - CREATED
    - STATUS 
    - PORTS 
    - NAMES 

02 - What is the version of container which you have worked on ? 
    - 29.6.1

03 - Explain docker images output ? 
    - IMAGE - Repository name and tag of the image. latest is the default tag.
    - ID - Short Image ID (first 12 characters of the SHA256 image digest).
    - DISK UAGE - Total disk space occupied by this image on your local machine, including shared layers and metadata.
    - CONTENT SIZE - Actual size of the image contents that would typically be downloaded from the registry.
    - EXTRA - Indicates the image is currently in use by at least one container.

vinod@vinod:~$ docker images
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
nginx:latest   ec4ed8b5299e        241MB           66MB    U
vinod@vinod:~$

What is the size of the nginx image? 66MB
How much disk space is Docker using for this image on your machine? 241MB 

04 - How vendor create the base images ? for example redhat minimal image ? 

05 - How to check the lables of a docker image ? how to check docker image information without running it ? 