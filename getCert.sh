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

azureConfigDir=/opt/jenkins/.azure-$subscription

command="az keyvault certificate download --vault-name $vaultName --name $certName --file $fileLocation/$certName.cer"

echo "Grabbing certificate"
echo "Using $subscription"
echo ""

if [ -d "$azureConfigDir" ]; then
	echo "Config dir found for subscription $subscription"
	echo "Grabbing certificate for $certName from $vaultName"
	echo ""
	result=$(env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$subscription bash -e $command)
else
	echo "Config dir not found - running under current login"
	echo "Grabbing certificate for $certName from $vaultName"
	echo ""
	result=$(bash -e $command)
fi

if [ -z "$result" ]; then
	echo "Cert retrieved successfully ..."
	echo ""
	cat $fileLocation/$certName.cer
	echo "Encoding file ..."
	echo ""
	base64 -i $fileLocation/$certName.cer >$fileLocation/$certName.base64.out
	cat $fileLocation/$certName.base64.out
else
	echo "Error retrieving cert ...."
	echo "$result"
	exit
fi