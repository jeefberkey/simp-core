#!/bin/bash

set -x

if [[ -d ".vagrant/beaker_vagrant_files" ]]; then
  for i in $(ls .vagrant/beaker_vagrant_files); do
    cd .vagrant/beaker_vagrant_files/$i
    vagrant destroy -f
    cd ../../..
  done
fi
