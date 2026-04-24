#!/bin/bash
sudo dnf install ansible -y
ansible-galaxy collection install amazon.aws:6.0.1 --force
component=$1
environment=$2
rm -rf ansible-roboshop-roles-tf
git clone https://github.com/mahesh-practice09/ansible-roboshop-roles-tf.git
cd ansible-roboshop-roles-tf
sudo ansible-playbook -e component=$component -e env=$environment roboshop.yaml