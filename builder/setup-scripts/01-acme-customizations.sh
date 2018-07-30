#!/bin/bash -xe
echo 'updating OS and installing base packages'

# update all packages
sudo yum -y update 

# install base packages
sudo yum -y install  \
  ansible \
  tmux \
  htop \
  vim \
  unzip \
  jq
  
# hack, remove existing ansible, resolve a strange bug
# sudo rm -rf /usr/local/lib/python2.7/dist-packages/ansible*

# TODO: move all pip packages into setup.py
sudo yum -y install python-pip
sudo pip install setuptools -U

# GY: Update to Linux HWE/LTS to reolve Intel CVEs
# how to do this??

# GCP tools
# how to do this

# no strict modes since our acme keys are placed in /etc
sudo sed -i 's/^StrictModes.*/StrictModes no/g' /etc/ssh/sshd_config