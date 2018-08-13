#! /bin/bash

set -e 

vaultName=${1}
cert=${2}

    certEntry=$(az keyvault secret show --vault-name ${vaultName} --name  ${cert} | jq -r .value | base64 -D | openssl pkcs12 -nodes -passin pass: | openssl pkcs12 -export -passout pass:${cert}  | base64 )
    cat << EOF >> certs.json
    {
    name = "${cert}" 
    data = "${certEntry}"
    password = "${cert}"
    },