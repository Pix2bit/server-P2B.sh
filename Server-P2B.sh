#!/bin/bash

# Kleuren en header
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"
IP=$(hostname -I | awk '{print $1}')
hostname="$(hostname)"

function header_info {
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
}

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

clear
header_info

# Controleer of de gebruiker sudo-rechten heeft
if [ "$(id -u)" -ne 0 ]; then
  echo "Dit script moet met sudo-rechten worden uitgevoerd. Gebruik 'sudo bash scriptnaam.sh'"
  exit 1
fi

# Vraag voor Code Server
INSTALL_CODE_SERVER="n"
while true; do
    read -p "Wil je dat Code Server geïnstalleerd wordt (y/n)? " yn
    case $yn in
    [Yy]*) INSTALL_CODE_SERVER="y"; break ;;
    [Nn]*) INSTALL_CODE_SERVER="n"; break ;;
    *) echo "Please answer yes or no." ;;
    esac
done

# Vraag voor Docker
INSTALL_DOCKER="n"
while true; do
    read -p "Wil je Docker Engine en Docker Compose installeren? (y/n)? " yn
    case $yn in
    [Yy]*) INSTALL_DOCKER="y"; break ;;
    [Nn]*) INSTALL_DOCKER="n"; break ;;
    *) echo "Please answer yes or no." ;;
    esac
done

# --- Code Server installatie ---
if [ "$INSTALL_CODE_SERVER" = "y" ]; then
    msg_info "Installing curl"
    apt-get update &>/dev/null
    apt-get install -y curl &>/dev/null
    msg_ok "Installed curl"

    VERSION=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest |
        grep "tag_name" |
        awk '{print substr($2, 3, length($2)-4) }')

    msg_info "Installing Code-Server v${VERSION}"
    curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb &>/dev/null
    dpkg -i code-server_${VERSION}_amd64.deb &>/dev/null
    rm -rf code-server_${VERSION}_amd64.deb
    mkdir -p ~/.config/code-server/
    systemctl enable -q --now code-server@$USER
    cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
EOF
    systemctl restart code-server@$USER
    msg_ok "Installed Code-Server v${VERSION} on $hostname"
    echo -e "Code Server is geïnstalleerd. Ga naar de onderstaande URL.\n${BL}http://$IP:8680${CL}\n"
else
    echo -e "Code Server wordt niet geïnstalleerd."
fi

# --- Docker installatie ---
if [ "$INSTALL_DOCKER" = "y" ]; then
  echo "Start de installatie van Docker..."

  # Stap 1: Systeem updaten en benodigde pakketten installeren
  echo -e "\n--- Stap 1: Systeem updaten en benodigde pakketten installeren ---"
  apt update
  apt install -y ca-certificates curl gnupg lsb-release

  # Stap 2: Voeg de officiële Docker GPG-sleutel toe
  echo -e "\n--- Stap 2: Voeg de officiële Docker GPG-sleutel toe ---"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Stap 3: Voeg de Docker repository toe aan APT sources
  echo -e "\n--- Stap 3: Voeg de Docker repository toe aan APT sources ---"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Stap 4: Update de pakketlijst opnieuw en installeer Docker Engine en Docker Compose
  echo -e "\n--- Stap 4: Update de pakketlijst opnieuw en installeer Docker Engine en Docker Compose ---"
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Stap 5: Voeg de gebruiker toe aan de 'docker' groep (optioneel)
  echo -e "\n--- Stap 5: Voeg de gebruiker toe aan de 'docker' groep (optioneel) ---"
  read -p "Wil je je huidige gebruiker ('$SUDO_USER') toevoegen aan de 'docker' groep om Docker zonder sudo te kunnen gebruiken? (y/N): " add_user_choice
  if [[ "$add_user_choice" =~ ^[Yy]$ ]]; then
    if [ -n "$SUDO_USER" ]; then
      usermod -aG docker "$SUDO_USER"
      echo "Gebruiker '$SUDO_USER' is toegevoegd aan de 'docker' groep."
      echo "Je moet uitloggen en opnieuw inloggen (of 'newgrp docker' uitvoeren) om de wijziging van kracht te laten worden."
    else
      echo "Kan de huidige gebruiker niet bepalen. Sla het toevoegen aan de 'docker' groep over."
    fi
  else
    echo "Gebruiker wordt niet toegevoegd aan de 'docker' groep. Je zult 'sudo' moeten gebruiken voor Docker commando's."
  fi

  # Stap 6: Verifieer de installatie
  echo -e "\n--- Stap 6: Verifieer de installatie ---"
  echo "Controleren of Docker is geïnstalleerd met 'docker run hello-world'..."
  if docker run hello-world; then
    echo "Docker Engine is succesvol geïnstalleerd en werkt."
  else
    echo "Er is een probleem opgetreden bij het verifiëren van de Docker Engine installatie."
  fi

  echo -e "\nControleren of Docker Compose is geïnstalleerd met 'docker compose version'..."
  if docker compose version; then
    echo "Docker Compose is succesvol geïnstalleerd."
  else
    echo "Er is een probleem opgetreden bij het verifiëren van de Docker Compose installatie."
  fi

  echo -e "\nInstallatie voltooid!"
else
  echo "Docker installatie wordt niet uitgevoerd."
fi
