# `ngx_http_voms_module` for developers

A devcontainer is ready to use for the developers. A set of packages without nginx are already installed.

## How to build and install nginx with or without httpg patch

To build and install the latest stable version of [nginx](http://nginx.org/en/download.html) (1.24.0) you have to copy the `nginx.repo` file (it is contained in the `docker` directory) into the `/etc/yum.repos.d/` directory and install nginx with `yum`:

```shell
$ sudo cp docker/nginx.repo /etc/yum.repos.d/
$ sudo yum install -y nginx
```

Otherwise, if you want to build and install the latest stable version of [nginx](http://nginx.org/en/download.html) (1.24.0) with the httpg patch, a bash library is ready to use. You can source it and follow the commands below:

```shell
$ source .devcontainer/assets/build-library.sh
$ downloadNginx
$ buildHttpgNginxRPM
$ sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/nginx-httpg-1.24.0-1.el7.ngx.x86_64.rpm
```

## How to build and install the `ngx_http_voms_module`

If you want to build and install the `ngx_http_voms_module`, nginx have to be installed in the container (see the previous section). When this requirement is satisfied, you can use the library contained in the `.devcontainer/assets` folder as follows (NOTE: if you have already download nginx source file, you can skip the relative command):

```shell
$ source .devcontainer/assets/build-library.sh
$ downloadNginx
$ buildVomsModuleRPM
$ sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/nginx-module-http-voms-1.24.0-1.el7.x86_64.rpm
```
## How to manage this project

If you want to understand how this project works, start from the CI. Three stages are defined:

### 1. build-rpms

Starting from a clear centos7, we install all the useful packages to compile nginx and to build a rpm package. The bash steps that achieves these results are defined in the `.devcontainer/assets/build-library.sh` file, so you can read that bash script to learn which nginx version we use, how to download it, how to set up the environment and how to build the rpm. 

It is important to underline that to build the nginx rpm we use the spec file in the `rpm` repo, that is the official nginx 1.24.0 spec file increased by the HTTPG patch. To build the `ngx_http_voms_module` we have defined an appropriate spec file indeed. The files that are used to build the rpm module are written, called and collocated following the common practices of the nginx modules: a source file is defined in the `src` folder, the `config` and the `config.make` files are in the root project directory.

At the end of this stage, all the useful rpms are saved as job artifacts.

### 2. docker-build-rpms

In this stage we set up a docker image with nginx, the httpg patch and the `ngx_http_voms_module`. To do this, we use a set of scripts written by Andrea Ceccanti in the [`helper-scripts`](https://baltig.infn.it/mw-devel/helper-scripts.git) project.

The dockerfile and all the files needed for its compilation are in the `docker` directory. The image starts from centos7, defines a user and installs a set of useful packages. After that we import the nginx repo file, in this way we can download a lot of packages provided by nginx, including its last stable version. In the end we install the rpm packages that we build in the previous stage and the njs module.

### 3. push-to-dockerhub

In this last stage we push on dockerhub the image that we have builded in the previous stage. Note that this stage is run only when we push something in the master branch.




