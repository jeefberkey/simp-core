#!/usr/bin/rake -T

require 'simp/rake/pupmod/helpers'

Simp::Rake::Beaker.new(File.dirname(__FILE__))

begin
  require 'simp/rake/build/helpers'
  BASEDIR    = File.dirname(__FILE__)
  Simp::Rake::Build::Helpers.new( BASEDIR )
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

task :metadata_lint do
  sh 'metadata-json-lint metadata.json'
end

multitask :build_images do
  sh 'docker build -t simp_core/build-el7 spec/acceptance/suites/rpm_docker/nodesets/docker_el7'
  sh 'docker build -t simp_core/build-el6 spec/acceptance/suites/rpm_docker/nodesets/docker_el6'
end

task :default do
  help
end
