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

    sudo sed -i 's/(?<=command=").*?(?="$)/' /root/.ssh/authorized_keys
    sudo apt-get update
    sudo apt-get install -y htop curl apt-transport-https software-properties-common
    sudo wget https://gist.githubusercontent.com/1benik/076196fdf11807fcba1d13104b446d18/raw/7c30b3cd056a3aae82e555930cf69152dc33a5d8/sources.list -O /etc/apt/sources.list
    sudo curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo wget https://gist.githubusercontent.com/1benik/9985b33f43a6b806b93badce37d33c34/raw/4b9762af0e72f8e6a691cc7286b1ad7fb0d7b335/saltstack.list -O /etc/apt/sources.list.d/saltstack.list
    sudo apt-get update
    sudo apt-get -y upgrade
    sudo rm -f /etc/localtime
    sudo ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
    sudo echo ${NEW_HOSTNAME} > /etc/hostname
    sudo sed -i 's/(?<=127\.0\.1\.1).*?(?=$)/$NEW_HOSTNAME' /etc/hosts

}

function after_reboot() {

    # IP_ADDR=$(curl ipinfo.io/ip | sed "s/\./\\\./g")
    # sudo sed -i 's/(?<=allow\s\^).*?(?=\$)/$IP_ADDR'

    sudo apt-get install -y munin munin-plugins-extra nginx syslog-ng syslog-ng-core python3-pip
    sudo wget https://gist.githubusercontent.com/1benik/8fcd361e2bebbdfb6cfea645e73770e8/raw/3fd854a94ef30cc938d23c8be8a2f10c27147e2b/syslog-ng.conf -O /etc/syslog-ng/syslog-ng.conf
    sudo wget https://gist.githubusercontent.com/1benik/f5b7e83a498c65e62f6d801a874ee208/raw/f0095682af2cc2a2ae42b7e6ae6464a35cfed4a1/munin.conf -O /etc/munin/munin.conf
    sudo wget https://gist.githubusercontent.com/1benik/551b303a82ba4d1c54c30959042fa80c/raw/abfa686fa958c453370272d49622f2ad4c6c7beb/central.bennink.me -O /etc/nginx/sites-available/central.bennink.me
    sudo wget https://gist.githubusercontent.com/1benik/98b8c65506064bc7c381eb77e0d8ecb6/raw/8c78962a8b218b5c1cf7ebc3e7897aeb740580bc/.htpasswd -O /etc/nginx/.htpasswd
    sudo wget https://gist.githubusercontent.com/1benik/2c1ef1d34665d17aa7527b0e94545afe/raw/779439a769381006ae7b16df14aee32fbb3ca96a/certificate.crt -O /etc/ssl/certs/central.bennink.me.crt
    sudo wget https://gist.githubusercontent.com/1benik/63b253ce2363701af53e889da528952a/raw/399294abd67b6fa4a4886e60ca61e5254861c616/private.key -O /etc/ssl/private/central.bennink.me.key
    sudo wget https://gist.githubusercontent.com/1benik/cb6f84612ba58eb4c2656b1a78179e73/raw/0796ae20740453d7510b4e07a53bf1be9beeaa9c/root.crt -O /etc/ssl/certs/lets_encrypt_root.crt
    sudo chown root:root /etc/ssl/private/central.bennink.me.key
    sudo chmod 640 /etc/ssl/private/central.bennink.me.key
    sudo ln -s /etc/nginx/sites-available/central.bennink.me /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo systemctl restart nginx.service syslog-ng.service
    sudo apt-get install salt-master salt-minion salt-ssh salt-cloud docker-ce git
    sudo pip3 install docker-py
    sudo mkdir -p /srv/salt/workers
    sudo wget https://gist.githubusercontent.com/1benik/c66a2e0ef2054c41811f4b21bcc1bfb3/raw/1609698f139a972c88cb091e2ac84918e8d894fc/master -O /etc/salt/master
    sudo wget https://gist.githubusercontent.com/1benik/e21c6c7669590cb849c97b47a410aa4f/raw/68335b458dcc91ea8ad4dacde234583d0f342f2b/minion-central -O  /etc/salt/minion
    sudo wget https://gist.githubusercontent.com/1benik/617169ce54c80389412a7d1e4c445a6e/raw/3a85332fb8d03821e20a03a3554a269fc1581bda/top.sls -O /srv/salt/top.sls
    sudo wget https://gist.githubusercontent.com/1benik/e3c3dce13d54e5b04b4f7baf23255cb6/raw/2eb610df25163f8701975e6c551bdf0d6d1e4e79/worker.sls -O /srv/salt/worker.sls
    sudo wget https://gist.githubusercontent.com/1benik/39dd45f439d0f401868c8c49355767b1/raw/03392ce450a28fa49b4f290f070a8d5ee608f753/syslog-ng-workers.conf -O /srv/salt/workers/syslog-ng.conf
    sudo wget https://gist.githubusercontent.com/1benik/453fc85e4e111072ccea4af243a3250d/raw/82e1e86b318ecb5053bcc4f000ab1c569e1be3fd/munin-node.conf -O /srv/salt/workers/munin-node.conf
    sudo systemctl restart salt-master.service salt-minion.service
    sudo docker swarm init
    sudo echo 'docker swarm join --token' $(docker swarm join-token -q worker) '10.4.0.10:2377' > /srv/salt/workers/docker-join.sh
    sudo salt '*' state.apply
}

if [ -f /var/run/reboot-required ]; then
    after_reboot
    sudo rm -f /var/run/reboot_required
    sudo update-rc.d central_init.sh remove
    sudo rm -f ~/central-init.sh
else
    before_reboot
    sudo touch /var/run/reboot-required
    sudo update-rc.d central_init.sh defaults
    sudo reboot
fi