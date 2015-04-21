require 'factor/connector/definition'
require 'travis'

class TravisConnectorDefinition < Factor::Connector::Definition
  id :travis

  action :rebuild do |params|
  end
end