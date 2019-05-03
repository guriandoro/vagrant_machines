#!/bin/bash
for f in `find . -maxdepth 1 -type d | tail -n +2`; do echo $f; cd $f; vagrant destroy --force; rm -rf .vagrant; cd ..;  done
