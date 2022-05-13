This folder contains the environment definition as a Docker image for the development of openresty-voms. It can be used as Dev Container in Visual Studio Code.

The *library-script* folder contains all the scripts needed for the build of the Dockerfile and for the definition of the environment:
   * *setup.sh* installs the packages for the development
   * *provide-user.sh* creates the DEV user and set its environment
   * *build-install-openresty.sh* configures, builds and installs openresty as a check to see if everything is ok
 
The *assets* folder contains all the scripts copied inside the container that could be used for the development:
   * *build-install-openresty-voms.sh* configures, builds and installs openresty-voms
   * *install-build-deps.sh* is used by the CI to install the packages for the deployment environment
