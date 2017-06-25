#!/usr/bin/env bash

### BEGIN INIT INFO
# Provides:          central-init.sh
# Required-Start:    networking
# Required-Stop:     networking
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: central-init.sh
# Description:       Dit script richt de centrale server in.
### END INIT INFO


function before_reboot() {

    NEW_HOSTNAME='central.bennink.me'
    CLI_NAME=$(echo ${NEW_HOSTNAME} | awk -F '[_.]' '{print $1}')

    sudo apt-get update
    sudo apt-get install -y htop curl apt-transport-https software-properties-common
    sudo wget https://gist.githubusercontent.com/1benik/076196fdf11807fcba1d13104b446d18/raw/7c30b3cd056a3aae82e555930cf69152dc33a5d8/sources.list -O /etc/apt/sources.list
    sudo systemctl mask unattended-upgrades
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade
    sudo apt-get install -y curl grub2 sshpass
    sudo update-grub2
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    sudo wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    sudo wget https://gist.githubusercontent.com/1benik/9985b33f43a6b806b93badce37d33c34/raw/4b9762af0e72f8e6a691cc7286b1ad7fb0d7b335/saltstack.list -O /etc/apt/sources.list.d/saltstack.list
    sudo rm -f /etc/localtime
    sudo ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
    sudo sed -i "s/$(cat /etc/hostname).novalocal/$NEW_HOSTNAME/g" /etc/hosts
    sudo sed -i "s/$(cat /etc/hostname | awk -F '[_.]' '{print $1}')/$CLI_NAME/g" /etc/hosts
    sudo sed -i "s/$(cat /etc/hostname)/$NEW_HOSTNAME/g" /etc/hostname
    sudo sshpass -p 'QHJktE8d7xF8cjVn' ssh -o StrictHostKeyChecking=no debian@worker1.bennink.me "sudo sed -i "s/MASTER/$(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')/g" /etc/salt/minion; sudo systemctl restart salt-minion.service"
    sudo sshpass -p 'QHJktE8d7xF8cjVn' ssh -o StrictHostKeyChecking=no debian@worker2.bennink.me "sudo sed -i "s/MASTER/$(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')/g" /etc/salt/minion; sudo systemctl restart salt-minion.service"

}

function after_reboot() {


    sudo apt-get install -y munin munin-plugins-extra nginx syslog-ng syslog-ng-core python3-pip
    sudo wget https://gist.githubusercontent.com/1benik/da8c10b04b8cd5937f5bdf9f9c703104/raw/55739a4ac74b81357c555ca6911c13c5f2cf4aaa/syslog-ng.conf -O /etc/syslog-ng/syslog-ng.conf
    sudo sed -i "s/MASTER/$(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')/g" /etc/syslog-ng/syslog-ng.conf
    sudo wget https://gist.githubusercontent.com/1benik/f5b7e83a498c65e62f6d801a874ee208/raw/319d3171c7310719113c1aae2955cc9f63200b7f/munin.conf -O /etc/munin/munin.conf
    WORKER1_IP=$(sshpass -p 'QHJktE8d7xF8cjVn' ssh -o StrictHostKeyChecking=no debian@worker1.bennink.me "ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'")
    WORKER2_IP=$(sshpass -p 'QHJktE8d7xF8cjVn' ssh -o StrictHostKeyChecking=no debian@worker2.bennink.me "ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'")
    sudo sed -i "s/MASTER/$WORKER1_IP/g" /etc/munin/munin.conf
    sudo sed -i "s/MASTER/$WORKER2_IP/g" /etc/munin/munin.conf
    sudo wget https://gist.githubusercontent.com/1benik/551b303a82ba4d1c54c30959042fa80c/raw/54ccee000173c43024317698101c9b53bc355091/central.bennink.me -O /etc/nginx/sites-available/central.bennink.me
    sudo wget https://gist.githubusercontent.com/1benik/98b8c65506064bc7c381eb77e0d8ecb6/raw/8c78962a8b218b5c1cf7ebc3e7897aeb740580bc/.htpasswd -O /etc/nginx/.htpasswd
    sudo wget https://gist.githubusercontent.com/1benik/2c1ef1d34665d17aa7527b0e94545afe/raw/779439a769381006ae7b16df14aee32fbb3ca96a/certificate.crt -O /etc/ssl/certs/central.bennink.me.crt
    sudo wget https://gist.githubusercontent.com/1benik/63b253ce2363701af53e889da528952a/raw/399294abd67b6fa4a4886e60ca61e5254861c616/private.key -O /etc/ssl/private/central.bennink.me.key
    sudo wget https://gist.githubusercontent.com/1benik/cb6f84612ba58eb4c2656b1a78179e73/raw/0796ae20740453d7510b4e07a53bf1be9beeaa9c/root.crt -O /etc/ssl/certs/lets_encrypt_root.crt
    sudo chown root:root /etc/ssl/private/central.bennink.me.key
    sudo chmod 640 /etc/ssl/private/central.bennink.me.key
    sudo ln -s /etc/nginx/sites-available/central.bennink.me /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo systemctl restart nginx.service syslog-ng.service
    sudo apt-get update
    sudo apt-get install -y salt-master salt-minion salt-ssh salt-cloud docker-engine
    sudo pip3 install docker-py
    sudo mkdir -p /srv/salt/worker
    sudo wget https://gist.githubusercontent.com/1benik/c66a2e0ef2054c41811f4b21bcc1bfb3/raw/1609698f139a972c88cb091e2ac84918e8d894fc/master -O /etc/salt/master
    sudo wget https://gist.githubusercontent.com/1benik/e21c6c7669590cb849c97b47a410aa4f/raw/68335b458dcc91ea8ad4dacde234583d0f342f2b/minion-central -O  /etc/salt/minion
    sudo wget https://gist.githubusercontent.com/1benik/617169ce54c80389412a7d1e4c445a6e/raw/3a85332fb8d03821e20a03a3554a269fc1581bda/top.sls -O /srv/salt/top.sls
    sudo wget https://gist.githubusercontent.com/1benik/e3c3dce13d54e5b04b4f7baf23255cb6/raw/bfe17dc76664c45b5cf91894c9f6ed52e7c1a32f/worker.sls -O /srv/salt/worker.sls
    sudo wget https://gist.githubusercontent.com/1benik/900dce3bf9dbf5cee18333571ae36863/raw/2548a64f33d3e08c51990d51eefa0100f5d74d47/syslog-ng-workers.conf -O /srv/salt/worker/syslog-ng.conf
    sudo wget https://gist.githubusercontent.com/1benik/453fc85e4e111072ccea4af243a3250d/raw/bc13a777467d1991ea45c27c70bf47305ef0d863/munin-node.conf -O /srv/salt/worker/munin-node.conf
    sudo sed -i "s/MASTER/$(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')/g" /srv/salt/worker/munin-node.conf
    sudo wget https://gist.githubusercontent.com/1benik/1ac59c666e7bc6954763dd7982907e7a/raw/6fa81d32e0eb10cce3b09f7b147a68034532b295/kubernetes.list -O /srv/salt/worker/kubernetes.list
    sudo systemctl restart salt-master.service salt-minion.service
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    sudo wget https://gist.githubusercontent.com/1benik/1ac59c666e7bc6954763dd7982907e7a/raw/6fa81d32e0eb10cce3b09f7b147a68034532b295/kubernetes.list -O /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni
    sudo kubeadm init
    cp /etc/kubernetes/admin.conf $HOME/
    chown $(id -u):$(id -g) $HOME/admin.conf
    KUBECONFIG=$HOME/admin.conf
    kubectl apply -n kube-system -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    sudo docker swarm init
    echo "docker swarm join --token $(sudo docker swarm join-token -q worker) $(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'):2377" | sudo tee /srv/salt/worker/docker-join.sh
    echo "kubeadm join --token $(sudo kubeadm token list | awk 'NR==2{print $1}') $(ip addr show eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'):6443" | sudo tee /srv/salt/worker/kubernetes-join.sh
    sudo salt '*' state.apply

}

if [ -f /var/run/init-reboot ]; then
    after_reboot
    sudo rm -f /var/run/init-reboot
    sudo update-rc.d central-init.sh remove
    sudo rm -f /etc/init.d/central-init.sh
else
    before_reboot
    sudo touch /var/run/init-reboot
    sudo update-rc.d central-init.sh defaults
    sudo reboot
fi