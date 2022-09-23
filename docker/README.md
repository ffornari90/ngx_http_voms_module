# Docker image for openresty-voms

This folder contains the *openresty-voms* folder, containing:

* The *Dockerfile* on which the CI installs the openresty-voms RPM with the NGINX-HTTPG patch.
* The *.env* file where some environment variables are defined. These variables are used during the building of the Docker image and for pushing and pulling the openresty-voms image on the docker registry.
* The *library-scripts* folder contains all the scripts needed to build the Docker image and for the definition of the environment.
* The *assets* folder contains all the files copied inside the container that are used during its execution. In particular, there is the *nginx.conf* file with the base configurations of the nginx-openresty instance that is running inside the container.
