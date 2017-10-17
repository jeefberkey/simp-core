FROM centos:6.6

# Beaker docker stuff
ENV container docker
RUN yum clean all
RUN yum install -y sudo openssh-server openssh-clients curl ntpdate yum-plugin-ovl
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN mkdir -p /var/run/sshd
RUN echo root:root | chpasswd
RUN sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?UseDNS .*/UseDNS no/' /etc/ssh/sshd_config

# For SELinux Builds
RUN yum install -y yum-utils deltarpm

# We only want to deal with the original distro packages
RUN yum-config-manager -q --disable \*
RUN echo -e "[legacy]\nname=Legacy\nbaseurl=http://vault.centos.org/6.6/os/x86_64\ngpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-6\ngpgcheck=1" > /etc/yum.repos.d/legacy.repo

# Getting rid of package conflicts
RUN \cp -a /etc/ssh /root
RUN yum downgrade -y openssh openssh-server openssh-clients
RUN yum install -y openssh-server
RUN \cp -a /root/ssh /etc

# Add the SELinux Build dependencies
RUN yum install -y selinux-policy-targeted selinux-policy-devel policycoreutils policycoreutils-python

# Allow the build user to perform privileged operations
RUN echo 'Defaults:build_user !requiretty' >> /etc/sudoers
RUN echo 'build_user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Add the build user
RUN useradd -b /home -G wheel -m -c "Build User" -s /bin/bash -U build_user

# No limits
RUN rm -rf /etc/security/limits.d/*.conf

# simp build-deps
RUN yum-config-manager --enable extras
RUN yum-config-manager --enable base
RUN yum install -y epel-release
RUN yum install -y openssl util-linux rpm-build augeas-devel createrepo genisoimage git gnupg2 libicu-devel libxml2 libxml2-devel libxslt libxslt-devel rpmdevtools clamav which ruby-devel rpm-sign acl

# simp doc deps
RUN yum -y install centos-release-scl python27 python-pip python-virtualenv fontconfig dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts dejavu-fonts-common libjpeg-devel zlib-devel

# RVM build-deps
RUN yum install -y libyaml-devel glibc-headers autoconf gcc gcc-c++ glibc-devel readline-devel libffi-devel openssl-devel automake libtool bison sqlite-devel tar

# Puppet Deps
RUN yum install -y ntpdate rubygems

# RVM
RUN runuser build_user -l -c "gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
RUN runuser build_user -l -c "curl -sSL https://get.rvm.io | bash -s stable"
RUN runuser build_user -l -c "rvm install 2.1.9"
RUN runuser build_user -l -c "rvm use --default 2.1.9"
RUN runuser build_user -l -c "rvm all do gem install bundler"

# Add some gems that will drag along 90% of what the build requires
RUN runuser build_user -l -c "rvm use default; gem install --no-ri --no-rdoc simp-rake-helpers"
RUN runuser build_user -l -c "rvm use default; gem install --no-ri --no-rdoc json"
RUN runuser build_user -l -c "rvm use default; gem install --no-ri --no-rdoc charlock_holmes"
RUN runuser build_user -l -c "rvm use default; gem install --no-ri --no-rdoc posix-spawn"

RUN yum clean all && rm -rf /var/cache/yum || true

EXPOSE 22

CMD ["/usr/sbin/sshd -D"]
