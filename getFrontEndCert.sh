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
file=$fileLocation/$certName.out

command="az keyvault secret download --vault-name $vaultName --name $certName --file $file -e base64"

echo "Grabbing Secret"
echo "Using $subscription"
echo ""

# Check if cert exists and remove
if [ -f $file ]; then
	echo "$file exists, removing"
	rm *.cer
	rm *.pfx
	rm *.out
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
	echo "Secret retrieved successfully ..."
	
else
	echo "Error retrieving cert ...."
	echo "$result"
	exit
fi

echo "Converting to base64"
# base64 -D $file > $file.pfx
echo
echo "Converting to PEM"
echo ""
openssl pkcs12 -in $file -out $file.pem -nodes -passin pass:
echo ""
echo "Adding passcode"
echo ""
