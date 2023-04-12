# `ngx_http_voms_module` for developers

A devcontainer is ready to use for the developers. A set of packages without nginx are already installed.

## How to build and install nginx with or without httpg patch

To build and install the last stable version of [nginx](http://nginx.org/en/download.html) (1.24.0) you have to copy the ```nginx.repo``` file (it is contained in the ```docker``` directory) into the ```/etc/yum.repos.d/``` directory and install nginx with yum:

```shell
$ sudo cp docker/nginx.repo /etc/yum.repos.d/
$ sudo yum install -y nginx
```

Otherwise, if you want to build and install the last stable version of [nginx](http://nginx.org/en/download.html) (1.24.0) with the httpg patch, a bash library is ready to use. You can source it and follow the commands below:

```shell
$ source .devcontainer/assets/build-library.sh
$ downloadNginx
$ buildHttpgNginxRPM
$ sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/nginx-httpg-1.24.0-1.el7.ngx.x86_64.rpm
```

## How to build and install the `ngx_http_voms_module`

If you want to build and install the `ngx_http_voms_module`, nginx have to be installed in the container (see the previous section). When this requirement is satisfied, you can use the library contained in the ```.devcontainer/assets``` folder as follows (NOTE: if you have already download nginx source file, you can skip the relative command):

```shell
$ source .devcontainer/assets/build-library.sh
$ downloadNginx
$ buildVomsModuleRPM
$ sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/nginx-module-http-voms-1.24.0-1.el7.x86_64.rpm
```
