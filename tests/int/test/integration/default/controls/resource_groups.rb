# encoding: utf-8
# copyright: 2017, The Authors
# license: All rights reserved
require 'rspec/retry'

title 'Check Azure Resource Group Configuration'

control 'azure-resource-groups' do

  impact 1.0
  title ' Check that the resource group exist'
  json_obj = json('.kitchen/kitchen-terraform/default-azure/terraform.tfstate')
  random_name = json_obj['modules'][0]['outputs']['random_name']['value'] + '-waf-int'

  describe azure_resource_group(name: random_name) do
    it 'should succeed after a while', retry: 10, retry_wait: 10 do
      its('location') {should eq 'uksouth'}
    end
  end
end
