This folder contains the environment definition as a Docker image for the development of openresty-voms. It can be used as Dev Container in Visual Studio Code.

The *library-scripts* folder contains all the scripts needed for the build of the Dockerfile and for the definition of the environment:
   * *provide-CI-deps.sh* installs the packages for the CI container. Theese same deps are the base deps for the devcontainer
   * *provide-dev-deps.sh* installs the ramained packages needed for the devcontainer
   * *provide-user.sh* creates the DEV user and set its environment
   * *build-install-openresty.sh* configures, builds and installs openresty as a check to see if everything is ok
 
The *assets* folder contains all the scripts copied inside the container that could be used for the development:
   * *build-install-openresty-voms.sh* configures, builds and installs openresty-voms