install packages:
  pkg.installed:
    - pkgs:
      - munin
      - munin-plugins-extra
      - syslog-ng
      - htop
      - python3-pip
      - apt-transport-https
      - software-properties-common

install docker-py:
  cmd.run:
    - name: easy_install docker-py

/etc/munin/munin-node.conf:
  file.managed:
    - name: /etc/munin/munin-node.conf
    - source: salt://worker/munin-node.conf

/etc/syslog-ng/syslog-ng.conf:
  file.managed:
    - name: /etc/syslog-ng/syslog-ng.conf
    - source: salt://worker/syslog-ng.conf

/etc/apt/sources.list.d/kubernetes.list:
  file.managed:
    - name: /etc/apt/sources.list.d/kubernetes.list
    - source: salt://worker/kubernetes.list

add kubernetes key:
  cmd.run:
    - name: curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

update repos:
  cmd.run:
    - name: apt-get update

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
    - name: apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

install docker and kubernetes:
  pkg.installed:
    - pkgs:
      - docker-engine
      - kubelet
      - kubeadm
      - kubectl
      - kubernetes-cni

docker-join.sh:
  cmd.script:
    - name: docker-join.sh
    - source: salt://worker/docker-join.sh

kubernetes-join.sh:
  cmd.script:
    - name: kubernetes-join.sh
    - source: salt://worker/kubernetes-join.sh

fetch docker image:
  dockerng.image_present:
    - force: true
    - name: benik/wordpress-container-linux-services

run wordpress docker:
  dockerng.running:
    - name: wordpress-container-linux-services
    - image: benik/wordpress-container-linux-services
    - port_bindings: 443:443