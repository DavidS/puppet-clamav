require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      # Install module and dependencies
      copy_module_to(host, :source => proj_root, :module_name => 'clamav')
      on host, puppet('module', 'install', 'puppetlabs-stdlib')

      if fact('osfamily') == 'RedHat'
        on host, puppet('module', 'install', 'stahnma/epel')
      end
    end
  end
end
