#!/bin/bash

#
#  Shell script to grab certificates from the vault and provider a base64 encoded version
#

# Force script to return -1 if any std errors
set -e

vaultName=$1
certName=$2
fileLocation=$3
subscription=$4

command="az keyvault certificate download --vault-name $vaultName --name $certName --file $fileLocation/$certName.cer"

echo "Grabbing certificate"
echo "Using $subscription"
echo  
result=$(env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$subscription bash -e $command)

echo $result

base64 -i $fileLocation/$certName.cer > $fileLocation/$certName.base64.out