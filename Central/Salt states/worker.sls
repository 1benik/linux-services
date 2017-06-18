install packages:
  pkg.installed:
    - pkgs:
      - munin
      - munin-plugins-extra
      - syslog-ng
      - htop
      - curl
      - python3-pip
      - apt-transport-https
      - software-properties-common

install docker-py:
  pip.installed:
    - name: docker-py
    - bin_env: '/usr/bin/pip3'

/etc/munin/munin-node.conf:
  file.managed:
    - name: /etc/munin/munin-node.conf
    - source: salt://workers/munin-node.conf

/etc/syslog-ng/syslog-ng.conf:
  file.managed:
    - name: /etc/syslog-ng/syslog-ng.conf
    - source: salt://workers/syslog-ng.conf

restart munin-node:
  module.run:
    - name: service.restart
    - m_name: munin-node

restart syslog-ng:
  module.run:
    - name: service.restart
    - m_name: syslog-ng

add docker key:
  cmd.run:
    - name: add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

install docker:
  pkg.installed:
    - pkgs:
      - docker-ce

docker-join.sh:
  cmd.script:
    - name: docker-join.sh
    - source: salt://workers/docker-join.sh

fetch docker image:
  dockerng.image_present:
    - force: true
    - name: benik/wordpress-container-linux-services

run wordpress docker:
  dockerng.running:
    - name: wordpress-container-linux-services
    - image: benik/wordpress-container-linux-services
    - port_bindings: 443:443