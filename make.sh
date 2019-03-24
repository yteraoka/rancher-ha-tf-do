#!/bin/bash

set -e

log(){
    echo "$(date +%Y-%m-%dT%H:%M:%S) $*"
}

download_lego(){
    log Download lego
    local uname=$(uname -s -m)
    local version=2.2.0
    local base_url=https://github.com/xenolf/lego/releases/download
    case "$uname" in
      "Linux x86_64")
          if [ ! -f lego ] ; then
              curl -Lo lego.tar.xz ${base_url}/v${version}/lego_v${version}_linux_amd64.tar.xz
	      tar xf lego.tar.xz lego
	      chmod 755 lego
	  fi
	  rm -f lego.tar.xz
	  ;;
      Darwin*)
          if [ ! -f lego ] ; then
              curl -Lo lego.tar.gz ${base_url}/v${version}/lego_v${version}_darwin_amd64.tar.gz
	      tar xf lego.tar.gz lego
	      chmod 755 lego
	  fi
	  rm -f lego.zip
	  ;;
      MINGW64*)
          if [ ! -f lego.exe ] ; then
              curl -Lo lego.zip ${base_url}/v${version}/lego_v${version}_windows_amd64.zip
	      unzip lego.zip lego.exe
	  fi
	  rm -f lego.zip
	  ;;
      *)
          echo "Unsupported platform $uname" 1>&2
	  exit 1
    esac
}


download_rke(){
    log Download rke
    local uname=$(uname -s -m)
    local version=0.1.16
    local base_url=https://github.com/rancher/rke/releases/download
    case "$uname" in
      "Linux x86_64")
          if [ ! -f rke ] ; then
              curl -Lo rke ${base_url}/v${version}/rke_linux-amd64
	  fi
	  chmod 755 rke
	  ;;
      Darwin*)
          if [ ! -f rke ] ; then
              curl -Lo rke ${base_url}/v${version}/rke_darwin-amd64
	  fi
	  chmod 755 rke
	  ;;
      MINGW64*)
          if [ ! -f rke.exe ] ; then
              curl -Lo rke.exe ${base_url}/v${version}/rke_windows-amd64.exe
	  fi
	  ;;
      *)
          echo "Unsupported platform $uname" 1>&2
	  exit 1
    esac
}


get_cert(){
    download_lego
    if [ ! -f .lego/certificates/rancher.${DOMAIN_SUFFIX}.crt ] ; then
        log Get certificate
        export DO_AUTH_TOKEN=$DIGITALOCEAN_TOKEN
        ./lego --domains rancher.${DOMAIN_SUFFIX} --email $CERT_EMAIL --accept-tos --dns digitalocean run
    fi
}


gen_rke_config() {
    log Generate rke.yml

    cat .lego/certificates/rancher.${DOMAIN_SUFFIX}.crt .lego/certificates/rancher.${DOMAIN_SUFFIX}.issuer.crt > .lego/certificates/rancher.${DOMAIN_SUFFIX}.bundle
    base64_crt=$(base64 -w 0 .lego/certificates/rancher.${DOMAIN_SUFFIX}.bundle)
    base64_key=$(base64 -w 0 .lego/certificates/rancher.${DOMAIN_SUFFIX}.key)

    curl -sLo 3-node-certificate-recognizedca.yml \
      https://raw.githubusercontent.com/rancher/rancher/master/rke-templates/3-node-certificate-recognizedca.yml

    addr0=$(terraform output -json | jq -r .node0_address.value)
    addr1=$(terraform output -json | jq -r .node1_address.value)
    addr2=$(terraform output -json | jq -r .node2_address.value)

    sed -e "1,/<IP>/s/<IP>/$addr0/" \
        -e "1,/<IP>/s/<IP>/$addr1/" \
        -e "1,/<IP>/s/<IP>/$addr2/" \
        -e "s/<USER>/rancher/" \
        -e "s/<PEM_FILE>/id_rsa/" \
        -e "s/<FQDN>/rancher.$DOMAIN_SUFFIX/" \
        -e "s/<BASE64_CRT>/$base64_crt/" \
        -e "s/<BASE64_KEY>/$base64_key/" \
       3-node-certificate-recognizedca.yml > rke.yml
}

wait_server_boot(){
    addr=$(terraform output -json | jq -r .node2_address.value)
    echo -n "Waiting for docker installed."
    i=0
    until timeout 5 ssh -i id_rsa -o StrictHostKeyChecking=no root@$addr docker ps > /dev/null 2>&1; do
        echo -n "."
        i=$(($i + 1))
	if [ $i -ge 300 ] ; then
	     echo "Given up the connecting to the server" 1>&2
	     exit 1
	fi
    done
    echo
}

cleanup(){
    rm -f rke* lego* *.yml
    rm -fr .lego
}

if [ -z "$DIGITALOCEAN_TOKEN" ] ; then
    echo "set DIGITALOCEAN_TOKEN first." 1>&2
    exit 1
fi

if [ -z "$DOMAIN_SUFFIX" ] ; then
    echo "set DOMAIN_SUFFIX first." 1>&2
    exit 1
fi

if [ -z "$CERT_EMAIL" ] ; then
    echo "set CERT_EMAIL first." 1>&2
    exit 1
fi

if [ ! -d .terraform ] ; then
    log terraform init
    terraform init
fi

if [ ! -f id_rsa ] ; then
    log Generate SSH key pair
    ssh-keygen -t rsa -b 2048 -P "" -f id_rsa
fi

case "$1" in
  # apply
  a*|u*)
      terraform plan \
        -var domain_suffix=$DOMAIN_SUFFIX \
	-out tf.plan
      terraform apply tf.plan
      wait_server_boot
      get_cert
      gen_rke_config
      download_rke
      log rke up
      ./rke up --config rke.yml
      echo
      echo "Try open https://rancher.${DOMAIN_SUFFIX}/"
      echo
    ;;
  d*)
      terraform destroy -var domain_suffix=$DOMAIN_SUFFIX
    ;;
  p*)
      terraform plan -var domain_suffix=$DOMAIN_SUFFIX
    ;;
  c*)
      terraform destroy -var domain_suffix=$DOMAIN_SUFFIX
      cleanup
    ;;
  *) echo "Usage: $0 {up|plan|destroy|cleanup}" 1>&2
     exit 1
esac
