#!/bin/bash

#
#  Shell script to upload specified files to a storage account
#

# Force script to return -1 if any std errors
set -e

connString=$1
source=$2
destination=$3
subscription=$4

command="az storage blob upload-batch --connection-string $connString --source $source --destination $destination"

echo "Uploading content"
if [ -z "$AZURE_CONFIG_DIR" ]; then
	echo "AZURE_CONFIG_DIR is not set - running under default AZ context"
	$command
else
	echo "AZURE_CONFIG_DIR is set - using $subscription"
	# env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$subscription az storage blob upload-batch --connection-string $connString --source $source --destination $destination
	env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$subscription $command
fi
