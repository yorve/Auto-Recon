#!/bin/bash 

#Personalización
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
ENDCOLOR="\e[0m"
BOLD="\e[1m"

#Comprobación

check_tools() {
    echo -e "${BLUE}[*] Verificando herramientas necesarias ${ENDCOLOR}"
    
    # Lista de herramientas que usa tu script
    dependencies=("nmap" "whatweb" "nikto" "gobuster" "ping" "awk")

    for tool in "${dependencies[@]}"; do
        # command -v devuelve 0 si encuentra la herramienta, 1 si no
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}[V] $tool encontrada.${ENDCOLOR}"
        else
            echo -e "${RED}[X] Error: La herramienta '$tool' no está instalada.${ENDCOLOR}"
            echo -e "${YELLOW}Por favor instálala antes de continuar.${ENDCOLOR}"
            exit 1 # Sale del script si falta algo
        fi
    done
    echo -e "${BLUE}[*] Todo listo para iniciar ${ENDCOLOR}"
    }

check_tools

print_banner() {
    cat << "EOF"
██  ██ ▄▄▄  ▄▄▄▄  ▄▄ ▄▄ ▄▄▄▄▄    ▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ 
 ▀██▀ ██▀██ ██▄█▄ ██▄██ ██▄▄    ██▀▀▀ ███▄▄ ██▄▄  ██▀▀▀ 
  ██  ▀███▀ ██ ██  ▀█▀  ██▄▄▄ ▄ ▀████ ▄▄██▀ ██▄▄▄ ▀████  v1.0
EOF
}

# Llamamos a la función para mostrar el banner
clear
print_banner

        echo ======================================================================
        echo -e "${BOLD}${YELLOW} Auto-Recon ${ENDCOLOR}multi escaneo automático para laboratorios de Pentesting"
        echo ======================================================================

        echo -e "${BOLD}${GREEN} Nombre del directorio de trabajo: ${ENDCOLOR}"
read nombre_directorio

        dir="$HOME/Desktop/$nombre_directorio"
        if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo ======================================================================
        echo -e "${BOLD}${YELLOW} Directorio creado. ${ENDCOLOR}"
else
        echo -e "${BOLD}${YELLOW} El directorio ya existe. ${ENDCOLOR}"
fi

cd "$dir" || exit

mkdir -p  nmap
        echo ======================================================================
        echo -e "${BOLD}${BLUE} El directorio actual de trabajo es $(pwd) ${ENDCOLOR}"
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Ingresa la ip del objetivo: ${ENDCOLOR}"

read ip
        ping -c1 "$ip" > /dev/null 2>&1

if [ $? -ne 0 ]; then
        echo -e "${RED} El host no responde, verifica la direción IP. ${ENDCOLOR}" 
        exit 1
fi

        echo ======================================================================
        echo -e "${BOLD}${GREEN} El host está activo ${ENDCOLOR}"
        echo ----------------------------------------------------------------------
        echo -e "${BOLD}${GREEN} Ejecutando escaneo de puertos ${ENDCOLOR}" 
        echo ======================================================================

#escaneo de puertos

nmap "$ip" -p- --open --min-rate 5000 -Pn -n -oN nmap/scan.txt
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Ejecutando escaneo de servicios: ${ENDCOLOR}"
        echo ======================================================================
        ports=$(awk '/\/tcp open/ {print $1}' nmap/scan.txt | cut -d/ -f1 | paste -sd,)

        nmap -sV -sC "$ip" -p "$ports" -oN nmap/servicios.txt

#whatweb

mkdir -p web

if [[  "$ports" == *"80"* || "$ports" == *"443"* || "$ports" == *"8080"*  ]]; then
        echo ====================================================================== 
        echo -e "${BOLD}${GREEN} Servicio Web detectado. ${ENDCOLOR}"
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Ejecutando WhatWeb. ${ENDCOLOR}"
        echo ======================================================================

        if [[ "$ports" == *"443"* ]]; then
                whatweb https://"$ip" | tee web/whatweb.txt
        else
                whatweb http://"$ip" | tee web/whatweb.txt
fi

#Nikto
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Ejecutando Nikto sobre el objetivo. ${ENDCOLOR}"
        echo ======================================================================
        if [[ "$ports" == *"443"* ]]; then
                nikto -h https://"$ip" -o web/nikto.txt
        else
                nikto -h http://"$ip" -o web/nikto.txt
fi


else
        echo "No se detectaron servicios web"
fi


#escaneo de directorios

if [[  "$ports" == *"80"* || "$ports" == *"443"* || "$ports" == *"8080"*  ]]; then
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Escaneando directorios web. ${ENDCOLOR}"
        echo ======================================================================
mkdir -p web/gobuster
        proto="http"
        if [[ "$ports" == *"443"* ]]; then
        proto="https"
fi
        echo ======================================================================
        echo -e "${BOLD}${GREEN} Ejecutando Gobuster sobre $proto://$ip ${ENDCOLOR}"
        echo ======================================================================

gobuster dir \
        -u $proto://$ip \
        -w /usr/share/wordlists/dirb/common.txt\
        -x php,txt,html \
        -t 40 \
        --no-error \
        -o web/gobuster/directorios.txt

else
        echo "No se detectaron servicios web para Gobuster"
fi