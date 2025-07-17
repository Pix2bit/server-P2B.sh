#!/bin/bash

# Controleer of de gebruiker sudo-rechten heeft
if [ "$(id -u)" -ne 0 ]; then
  echo "Dit script moet met sudo-rechten worden uitgevoerd. Gebruik 'sudo bash install_docker.sh'"
  exit 1
fi

echo "Dit script zal Docker Engine en Docker Compose (als plugin) installeren op je Ubuntu server."
read -p "Wil je doorgaan met de installatie? (y/N): " choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "Start de installatie van Docker..."

  # --- Stap 1: Systeem updaten en benodigde pakketten installeren ---
  echo -e "\n--- Stap 1: Systeem updaten en benodigde pakketten installeren ---"
  apt update
  apt install -y ca-certificates curl gnupg lsb-release

  # --- Stap 2: Voeg de officiële Docker GPG-sleutel toe ---
  echo -e "\n--- Stap 2: Voeg de officiële Docker GPG-sleutel toe ---"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # --- Stap 3: Voeg de Docker repository toe aan APT sources ---
  echo -e "\n--- Stap 3: Voeg de Docker repository toe aan APT sources ---"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  # --- Stap 4: Update de pakketlijst opnieuw en installeer Docker Engine en Docker Compose ---
  echo -e "\n--- Stap 4: Update de pakketlijst opnieuw en installeer Docker Engine en Docker Compose ---"
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # --- Stap 5: Voeg de gebruiker toe aan de 'docker' groep (optioneel) ---
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

  # --- Stap 6: Verifieer de installatie ---
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
  echo "Installatie geannuleerd."
  exit 0
fi
