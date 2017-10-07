#!/usr/bin/rake -T

# require 'simp/rake/pupmod/helpers'
# require 'simp/rake'
#
# Simp::Rake::Beaker.new(File.dirname(__FILE__))
#
# begin
#   require 'simp/rake/build/helpers'
#   BASEDIR    = File.dirname(__FILE__)
#   Simp::Rake::Build::Helpers.new( BASEDIR )
# rescue LoadError => e
#   warn "WARNING: #{e.message}"
# end
#
# task :metadata_lint do
#   sh 'metadata-json-lint metadata.json'
# end
#
# task :default do
#   help
# end

def spec_item(spec_file, pattern)
  File.readlines(spec_file).grep(pattern)[0].split(' ')[1]
end

namespace :docker do
  task :build do
    sh 'docker build -t simp/centos7-build .'
  end
end

'docker run -it -v $(pwd):/simp-build:Z -w /simp-build -e "usr=$(id -u)" simp/centos7-build'
namespace :assets do
  task :environment do
    path      = '/src/assets/environment'
    spec_file = 'src/assets/environment/build/simp-environment.spec'
    name      = spec_item(spec_file, /Name:/)
    version   = spec_item(spec_file, /Version:/)
    release   = spec_item(spec_file, /Release:/)

    docker = 'docker run -e "usr=$(id -u)" -v $(pwd)/src/assets/environment:/simp-build simp/centos7-build'
    sh "#{docker} tar --exclude-vcs -czvf #{name}-#{version}-#{release}.tar.gz /simp-build/*"
    sh "#{docker} rpmbuild --clean --buildroot dist/rpmbuild build/simp-environment.spec"
  end
end
