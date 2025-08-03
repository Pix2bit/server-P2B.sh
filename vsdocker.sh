#!/bin/bash

IP=$(hostname -I | awk '{print $1}')
hostname="$(hostname)"

cat <<"EOF"
                               ++++++++++++++++++++++++++++++++++
          _          _       +++  ____         _     _ _       ++
    _ __ (_)_  _____| |___  +++++|___ \       | |__ (_) |_ ___   
   | '_ \| \ \/ / _ \ / __|+++     __) |    + | '_ \| | __/ __|  
   | |_) | |>  <  __/ \__ \ +     / __/    +++| |_) | | |_\__ \  
   | .__/|_/_/\_\___|_|___/      |_____|+++++ |_.__/|_|\__|___/  
 ++|_|                                   +++                     
 ++++++++++++++++++++++++++++++++++++++++++                       

***Pixels2bits client server***

EOF

if [ "$(id -u)" -ne 0 ]; then
  echo "Dit script moet met sudo-rechten worden uitgevoerd. Gebruik 'sudo bash scriptnaam.sh'"
  exit 1
fi

read -p "Wil je dat Code Server geïnstalleerd wordt (y/n)? " yn_code
read -p "Wil je dat Docker geïnstalleerd wordt (y/n)? " yn_docker

code_server_geinstalleerd=false

if [[ "$yn_code" =~ ^[Yy]$ ]]; then
    apt-get update &>/dev/null
    apt-get install -y curl &>/dev/null

    VERSION=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

    curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb &>/dev/null
    dpkg -i code-server_${VERSION}_amd64.deb &>/dev/null
    rm -rf code-server_${VERSION}_amd64.deb
    mkdir -p ~/.config/code-server/
    systemctl enable -q --now code-server@$USER
    cat <<EOF2 >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
EOF2
    systemctl restart code-server@$USER
    echo "Code Server is geïnstalleerd."
    code_server_geinstalleerd=true
else
    echo "Code Server is niet geïnstalleerd."
    if [ -f ~/.config/code-server/config.yaml ]; then
        echo "De configuratie is gevonden op ~/.config/code-server/config.yaml"
    else
        echo "De configuratie is niet gevonden."
    fi
fi

if [[ "$yn_docker" =~ ^[Yy]$ ]]; then
    set -e
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    docker run hello-world
    docker compose version
    echo "Docker is geïnstalleerd."
else
    echo "Docker is niet geïnstalleerd."
fi

if [[ "$code_server_geinstalleerd" == true ]]; then
    echo "Ga naar: http://$IP:8680 om Code Server te gebruiken."
fi
