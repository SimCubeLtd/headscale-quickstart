#!/bin/bash

cat << "EOF"
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                                                         
        ██╗  ██╗███████╗ █████╗ ██████╗ ███████╗ ██████╗ █████╗ ██╗     ███████╗
        ██║  ██║██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██║     ██╔════╝
        ███████║█████╗  ███████║██║  ██║███████╗██║     ███████║██║     █████╗  
        ██╔══██║██╔══╝  ██╔══██║██║  ██║╚════██║██║     ██╔══██║██║     ██╔══╝  
        ██║  ██║███████╗██║  ██║██████╔╝███████║╚██████╗██║  ██║███████╗███████╗
        ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EOF


check_if_root() {
    if [ $(id -u) -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
    fi
}

check_dependencies() {
    echo "checking dependencies..."

    OS=$(uname)

    if [ -f /etc/debian_version ]; then
        dependencies="jq docker.io docker-compose"
        update_cmd='apt update'
        install_cmd='apt-get install -y'
    elif [ -f /etc/alpine-release ]; then
        dependencies="jq docker.io docker-compose"
        update_cmd='apk update'
        install_cmd='apk --update add'
    elif [ -f /etc/centos-release ]; then
        dependencies="jq docker.io docker-compose"
        update_cmd='yum update'
        install_cmd='yum install -y'
    elif [ -f /etc/fedora-release ]; then
        dependencies="jq docker.io docker-compose"
        update_cmd='dnf update'
        install_cmd='dnf install -y'
    elif [ -f /etc/redhat-release ]; then
        dependencies="jq docker.io docker-compose"
        update_cmd='yum update'
        install_cmd='yum install -y'
    elif [ -f /etc/arch-release ]; then
            dependecies="jq docker.io docker-compose"
        update_cmd='pacman -Sy'
        install_cmd='pacman -S --noconfirm'
    elif [ "${OS}" = "FreeBSD" ]; then
        dependencies="wget jq docker.io docker-compose"
        update_cmd='pkg update'
        install_cmd='pkg install -y'
    elif [ -f /etc/turris-version ]; then
        dependencies="bash jq docker.io docker-compose"
        OS="TurrisOS"
        update_cmd='opkg update'	
        install_cmd='opkg install'
    elif [ -f /etc/openwrt_release ]; then
        dependencies="bash jq docker.io docker-compose"ß
        OS="OpenWRT"
        update_cmd='opkg update'	
        install_cmd='opkg install'
    else
        install_cmd=''
    fi

    if [ -z "${install_cmd}" ]; then
            echo "OS unsupported for automatic dependency install"
        exit 1
    fi

    set -- $dependencies

    ${update_cmd}

    while [ -n "$1" ]; do
        if [ "${OS}" = "FreeBSD" ]; then
            is_installed=$(pkg check -d $1 | grep "Checking" | grep "done")
            if [ "$is_installed" != "" ]; then
                echo "  " $1 is installed
            else
                echo "  " $1 is not installed. Attempting install.
                ${install_cmd} $1
                sleep 5
                is_installed=$(pkg check -d $1 | grep "Checking" | grep "done")
                if [ "$is_installed" != "" ]; then
                    echo "  " $1 is installed
                elif [ -x "$(command -v $1)" ]; then
                    echo "  " $1 is installed
                else
                    echo "  " FAILED TO INSTALL $1
                    echo "  " This may break functionality.
                fi
            fi	
        else
            if [ "${OS}" = "OpenWRT" ] || [ "${OS}" = "TurrisOS" ]; then
                is_installed=$(opkg list-installed $1 | grep $1)
            else
                is_installed=$(dpkg-query -W --showformat='${Status}\n' $1 | grep "install ok installed")
            fi
            if [ "${is_installed}" != "" ]; then
                echo "    " $1 is installed
            else
                echo "    " $1 is not installed. Attempting install.
                ${install_cmd} $1
                sleep 5
                if [ "${OS}" = "OpenWRT" ] || [ "${OS}" = "TurrisOS" ]; then
                    is_installed=$(opkg list-installed $1 | grep $1)
                else
                    is_installed=$(dpkg-query -W --showformat='${Status}\n' $1 | grep "install ok installed")
                fi
                if [ "${is_installed}" != "" ]; then
                    echo "    " $1 is installed
                elif [ -x "$(command -v $1)" ]; then
                    echo "  " $1 is installed
                else
                    echo "  " FAILED TO INSTALL $1
                    echo "  " This may break functionality.
                fi
            fi
        fi
        shift
    done

    echo "-----------------------------------------------------"
    echo "dependency check complete"
    echo "-----------------------------------------------------"

    wait_seconds 3
}

wait_seconds() {(
  for ((a=1; a <= $1; a++))
  do
    echo ". . ."
    sleep 1
  done
)}

confirm() {(
  while true; do
      read -p 'Does everything look right? [y/n]: ' yn
      case $yn in
          [Yy]* ) override="true"; break;;
          [Nn]* ) echo "exiting..."; exit 1;;
          * ) echo "Please answer yes or no.";;
      esac
  done
)}

pull_config() {
    COMPOSE_URL="https://raw.githubusercontent.com/SimCubeLtd/headscale-quickstart/main/docker-compose.yaml" 
    CADDY_URL="https://raw.githubusercontent.com/SimCubeLtd/headscale-quickstart/main/Caddyfile"
    CONFIG_URL="https://raw.githubusercontent.com/SimCubeLtd/headscale-quickstart/main/config.yaml"
    echo "Pulling config files..."
    mkdir -p ./config
    mkdir -p ./data
    wget -O ./docker-compose.yml $COMPOSE_URL && wget -O ./Caddyfile $CADDY_URL && wget -O ./config/config.yaml $CONFIG_URL
    touch ./config/db.sqlite
}

test_connection() {
    local RETRY_URL=$1
    echo "Testing Caddy setup (please be patient, this may take 1-2 minutes)"
    for i in 1 2 3 4 5 6 7 8
    do
    curlresponse=$(curl -vIs $RETRY_URL 2>&1)

    if [[ "$i" == 8 ]]; then
    echo "    Caddy is having an issue setting up certificates, please investigate (docker logs caddy)"
    echo "    Exiting..."
    exit 1
    elif [[ "$curlresponse" == *"failed to verify the legitimacy of the server"* ]]; then
    echo "    Certificates not yet configured, retrying..."

    elif [[ "$curlresponse" == *"left intact"* ]]; then
    echo "    Certificates ok"
    break
    else
    secs=$(($i*5+10))
    echo "    Issue establishing connection...retrying in $secs seconds..."       
    fi
    sleep $secs
    done
}

install() {
    set -e

    CONFIG_DIR="/root/headscale"
    HEADSCALE_BASE_DOMAIN=headscale.$(curl -s ifconfig.me | tr . -).nip.io
    SERVER_PUBLIC_IP=$(curl -s ifconfig.me)

    mkdir -p $CONFIG_DIR
    pushd $CONFIG_DIR

    echo "-----------------------------------------------------"
    echo "Would you like to use your own domain for headscale, or an auto-generated domain?"
    echo "To use your own domain, add a Wildcard DNS record (e.x: *.headscale.example.com) pointing to $SERVER_PUBLIC_IP"
    echo "-----------------------------------------------------"
    select domain_option in "Auto Generated ($HEADSCALE_BASE_DOMAIN)" "Custom Domain (e.x: headscale.example.com)"; do
    case $REPLY in
        1)
        echo "using $HEADSCALE_BASE_DOMAIN for base domain"
        DOMAIN_TYPE="auto"
        break
        ;;      
        2)
        read -p "Enter Custom Domain (make sure  *.domain points to $SERVER_PUBLIC_IP first): " domain
        HEADSCALE_BASE_DOMAIN=$domain
        echo "using $HEADSCALE_BASE_DOMAIN"
        DOMAIN_TYPE="custom"
        break
        ;;
        *) echo "invalid option $REPLY";;
    esac
    done

    wait_seconds 2

    echo "-----------------------------------------------------"
    echo "The following subdomains will be used:"
    echo "          dashboard.$HEADSCALE_BASE_DOMAIN"
    echo "                api.$HEADSCALE_BASE_DOMAIN"
    echo "-----------------------------------------------------"

    if [[ "$DOMAIN_TYPE" == "custom" ]]; then
        echo "before continuing, confirm DNS is configured correctly, with records pointing to $SERVER_PUBLIC_IP"
        confirm
    fi

    wait_seconds 1

    unset GET_EMAIL
    unset RAND_EMAIL
    RAND_EMAIL="$(echo $RANDOM | md5sum  | head -c 16)@email.com"
    read -p "Email Address for Domain Registration (click 'enter' to use $RAND_EMAIL): " GET_EMAIL
    if [ -z "$GET_EMAIL" ]; then
    echo "using rand email"
    EMAIL="$RAND_EMAIL"
    else
    EMAIL="$GET_EMAIL"
    fi

    wait_seconds 2

    echo "-----------------------------------------------------------------"
    echo "                SETUP ARGUMENTS"
    echo "-----------------------------------------------------------------"
    echo "        domain: $HEADSCALE_BASE_DOMAIN"
    echo "         email: $EMAIL"
    echo "     public ip: $SERVER_PUBLIC_IP"
    echo "-----------------------------------------------------------------"
    echo "Confirm Settings for Installation"
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

    confirm

    echo "-----------------------------------------------------------------"
    echo "Beginning installation..."
    echo "-----------------------------------------------------------------"

    wait_seconds 3

    pull_config

    echo "Setting up configuration files..."

    sed -i "s|HEADSCALE_BASE_DOMAIN|${HEADSCALE_BASE_DOMAIN}|g" ./docker-compose.yml
    sed -i "s|HEADSCALE_BASE_DOMAIN|${HEADSCALE_BASE_DOMAIN}|g" ./Caddyfile
    sed -i "s|HEADSCALE_BASE_DOMAIN|${HEADSCALE_BASE_DOMAIN}|g" ./config/config.yaml
    sed -i "s|CONFIG_FOLDER|${CONFIG_DIR}|g" ./config/config.yaml
    sed -i "s|YOUR_EMAIL|${EMAIL}|g" ./Caddyfile
    
    echo "Starting containers..."

    docker-compose -f ./docker-compose.yml up -d

    sleep 2

    test_connection "https://api.${HEADSCALE_BASE_DOMAIN}"

    wait_seconds 3

    set +e

    echo "-----------------------------------------------------------------"
    echo "-----------------------------------------------------------------"
    echo "Headscale setup is now complete. You are ready to begin using Headscale."
    echo "WebUI Running On: https://dashboard.$HEADSCALE_BASE_DOMAIN"
    echo "Controller Running On: https://api.$HEADSCALE_BASE_DOMAIN"
    echo "-----------------------------------------------------------------"
    echo "-----------------------------------------------------------------"

    popd
}

check_if_root
check_dependencies
install