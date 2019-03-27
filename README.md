# rancher-ha-tf-do
Building HA Rancher 2.x server on DigitalOcean using Terraform and RKE

## Prerequisite

* [Terraform](https://www.terraform.io/) binary ([tfenv](https://github.com/tfutils/tfenv) recommended)
* [DigitalOcean](https://www.digitalocean.com/) account and API Token
* Own your custom domain and register zone in DigitalOcean DNS service
* [jq](https://stedolan.github.io/jq/) command

## Usage

### clone this repository

```
git clone https://github.com/yteraoka/rancher-ha-tf-do.git
```

### Build HA Rancher cluster

```
export DIGITALOCEAN_TOKEN=***
export DOMAIN_SUFFIX=your.own.example.com
export CERT_EMAIL=user@example.com # for Let's Encrypt
./make.sh up
```

Then open https://rancher.${DOMAIN_SUFFIX}/

`rke` creates `kube_config_rke.yml`.
If you want to access k8s using kubectl copy it to `~/.kube/config` or set environment variable `KUBECONFIG=kube_config_rke.yml`.

### Destroy cluster

Delete droplet (server), Load Balancer and DNS record.

```
export DIGITALOCEAN_TOKEN=***
export DOMAIN_SUFFIX=your.own.example.com
export CERT_EMAIL=user@example.com # for Let's Encrypt
./make.sh destroy
```
