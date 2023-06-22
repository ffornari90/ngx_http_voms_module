yum -y install epel-release
yum install -y wget openssl-devel zlib-devel pcre2-devel make rpmdevtools rpmlint boost-devel voms-devel gcc-c++
source .devcontainer/assets/build-library.sh 
downloadNginx
buildHttpgNginxRPM
buildVomsModuleRPM
mkdir docker/artifacts
cp ~/rpmbuild/SRPMS/* docker/artifacts/ 
cp ~/rpmbuild/RPMS/x86_64/* docker/artifacts/
