#!/bin/bash

#
#  Shell script to grab certificates from the vault and provider a base64 encoded version
#

# Force script to return -1 if any std errors
set -e

env=$1
certName=$2
fileLocation=$3
subscription=$4

azureConfigDir=/opt/jenkins/.azure-$subscription
file=$fileLocation/$certName.out

if [[ $env = *v2 ]]; then
	echo "Not fetching certificate as it is not needed in the new environment"
	exit 0
fi

vaultName="core-compute-$env"
command="az keyvault certificate download --vault-name $vaultName --name $certName --file $file"

echo "Grabbing certificate"
echo "Using $subscription"
echo ""

# Check if cert exists and remove
if [ -f $file ]; then
	echo "$file exists, removing"
	rm $file
	rm $file.2
else
	echo "$file not present"
fi

if [ -d "$azureConfigDir" ]; then
	echo "Config dir found for subscription $subscription"
	echo "Grabbing certificate for $certName from $vaultName"
	echo ""
	echo "Running command"
	echo "env AZURE_CONFIG_DIR=$azureConfigDir bash -e $command"
	result=$(env AZURE_CONFIG_DIR=$azureConfigDir bash -e $command)
else
	echo "Config dir not found - running under current login"
	echo "Grabbing certificate for $certName from $vaultName"
	echo ""
	result=$(bash -e $command)
fi

if [ -z "$result" ]; then
	echo "Cert retrieved successfully ..."
	echo ""
	cat $file
	echo ""
	echo ""
	echo "Formatting file"
	echo ""
	cat $file | tr -d '\n' | sed s/'-----BEGIN CERTIFICATE-----'// | sed s/'-----END CERTIFICATE-----'// >$file.2

	cat $file.2

else
	echo "Error retrieving cert ...."
	echo "$result"
	exit
fi
