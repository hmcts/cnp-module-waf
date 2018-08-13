#! /bin/bash

set -e 

vaultName=${1}
cert=${2}
path=${3}

certEntry=$(az keyvault secret show --vault-name ${vaultName} --name  ${cert} | jq -r .value | base64 -D | openssl pkcs12 -nodes -passin pass: | openssl pkcs12 -export -passout pass:${cert}  | base64)
echo "command = az keyvault secret show --vault-name ${vaultName} --name  ${cert} | jq -r .value | base64 -D | openssl pkcs12 -nodes -passin pass: | openssl pkcs12 -export -passout pass:${cert}  | base64 "
echo "{name = \"${cert}\", data = \"${certEntry}\", password = \"${cert}\"}," >> certs.json


