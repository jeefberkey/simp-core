# # bundle package --all
# docker build -t simp/centos7-build .
# docker run -it -v $(pwd):/simp-core:Z -w /simp-core -e 'SIMP_BUILD_checkout=no' -e 'SIMP_PKG_verbose=yes' simp/centos7-build bundle exec rake 'build:auto[ISO]'
# docker run -it -v $(pwd):/simp-core:Z -w /simp-core -e 'u=$(id -u)' simp/centos7-build chown -R 65535:65535 /simp-core

# This needs to be the *oldest* image of EL7 to preserve SELinux build compatibility
FROM centos:7.0.1406

RUN yum install -y yum-utils epel-release deltarpm && \
    yum-config-manager --disable *

COPY docker/legacy.repo /etc/yum.repos.d/legacy.repo

RUN yum remove -y fakesystemd && \
    yum downgrade -y openssh openssh-clients systemd-libs && \
    yum install -y openssh-server selinux-policy-targeted selinux-policy-devel policycoreutils policycoreutils-python

RUN yum-config-manager --enable extras && \
    yum-config-manager --enable base && \
    yum install -y openssl util-linux rpm-build augeas-devel createrepo genisoimage git gnupg2 libicu-devel libxml2 libxml2-devel libxslt libxslt-devel rpmdevtools clamav clamav-update which ruby-devel rpm-devel rpm-sign ntpdate autoconf automake bison gcc-c++ libffi-devel libtool readline-devel sqlite-devel glibc-headers glibc-devel libyaml-devel openssl-devel && \
    yum clean all

RUN ln -sf /bin/true /usr/bin/systemctl && \
    rm -rf /etc/security/limits.d/*.conf

# su and runuser cant do login shell, rvm needs it (from entrypoint)
# ditch rvm or figure out how to run it without login shell

##RUN echo 'export rvm_prefix="$HOME"' > /root/.rvmrc; \
##    echo 'export rvm_path="$HOME/.rvm"' >> /root/.rvmrc
#ENV BUNDLE_PATH /root/bundle_cache
#RUN command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -; \
#    curl -sSL https://get.rvm.io | bash -s stable --ruby='2.1.9' --auto-dotfiles --gems=bundler

ENV BUNDLE_PATH /var/local/bundle_cache
ENV RBENV_ROOT /usr/local/rbenv
WORKDIR /usr/local
RUN git clone https://github.com/rbenv/rbenv.git rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build && \
    chmod -R g+rwxXs rbenv
RUN sed -i 's/https/http/' /usr/local/rbenv/plugins/ruby-build/share/ruby-build/2.1.9 && \
    /usr/local/rbenv/bin/rbenv install 2.1.9 && \
    /usr/local/rbenv/bin/rbenv global 2.1.9 && \
    /usr/local/rbenv/shims/gem install bundler


COPY Gemfile Gemfile.lock /root/
WORKDIR /root
RUN /usr/local/rbenv/shims/bundle install --without system_tests && \
    chmod -R ugo+rX /var/local/bundle_cache && \
    chmod -R ugo+rX /usr/local/rbenv

COPY docker/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

