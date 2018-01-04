# vagrant_machines
scripts to bring up vagrant machines

# Quick bring up various distros

## Centos 7
vagrant init centos/7; vagrant up --provider virtualbox; vagrant ssh

## Cetnos 6
vagrant init centos/6; vagrant up --provider virtualbox; vagrant ssh

## Ubuntu 16.04
vagrant init ubuntu/xenial64; vagrant up --provider virtualbox ; vagrant ssh

## Ubuntu 14.04
vagrant init ubuntu/trusty64; vagrant up --provider virtualbox ; vagrant ssh

## Ubuntu 12.04
vagrant init ubuntu/precise64; vagrant up --provider virtualbox; vagrant ssh

## openSUSE-42.3
vagrant init opensuse/openSUSE-42.3-x86_64; vagrant up --provider virtualbox ; vagrant ssh

