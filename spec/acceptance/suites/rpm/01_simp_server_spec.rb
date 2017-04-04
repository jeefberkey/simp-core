require 'spec_helper_integration'
require 'erb'

test_name 'puppetserver via rpm'

describe 'install SIMP via rpm' do

  masters     = hosts_with_role(hosts, 'master')
  agents      = hosts_with_role(hosts, 'agent')
  master_fqdn = fact_on(master, 'fqdn')
  domain      = fact_on(master, 'domain')

  hosts.each do |host|
    it 'should set the root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo password | passwd root --stdin')
    end
    it 'should set up SIMP repositories' do
      on(host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X/script.rpm.sh | bash')
      on(host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash')
    end
  end

  context 'master' do
    let(:simp_conf_template) { File.read(File.open('spec/acceptance/suites/rpm/files/simp_conf.yaml.erb')) }
    masters.each do |master|
      it 'should install simp' do
        master.install_package('simp-adapter-foss')
        master.install_package('simp')
        on(master, 'yum makecache')
      end
      it 'should run simp config' do
        # grub password: H.SxdcuyF56G75*3ww*HF#9i-eDM3Dp5
        # ldap root password: Q*AsdtFlHSLp%Q3tsSEc3vFbFx5Vwe58
        create_remote_file(master, '/root/simp_conf.yaml', ERB.new(simp_conf_template).result(binding))
        # require 'pry';binding.pry
        on(master, 'simp config -a /root/simp_conf.yaml')
      end
      it 'should provide default hieradata to make beaker happy' do
        create_remote_file(master, '/etc/puppetlabs/code/environments/simp/hieradata/default.yaml', <<-EOF
          sudo::user_specifications:
            vagrant_all:
              user_list: ['vagrant']
              cmnd: ['ALL']
              passwd: false
          pam::access::users:
            defaults:
              origins:
                - ALL
              permission: '+'
            vagrant:
          ssh::server::conf::permitrootlogin: true
          ssh::server::conf::authorizedkeysfile: .ssh/authorized_keys
          EOF
        )
      end
      it 'should run simp bootstrap' do
        on(master, 'simp bootstrap --no-verbose -u --remove_ssldir > /dev/null', :accept_all_exit_codes => true)
        on(master, 'simp bootstrap --no-verbose -u --remove_ssldir > /dev/null')
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0,2] )
      end
      it 'should reboot the host' do
        master.reboot
      end
      it 'should have puppet runs with no changes' do
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0] )
      end
    end
  end

  # context 'classify nodes' do
  # end

  context 'agents' do
    agents.each do |agent|
      it 'should run the agent' do
        # require 'pry';binding.pry if fact_on(agent, 'hostname') == 'agent'
        on(agent, "puppet agent -t --ca_port 8141 --server #{master_fqdn}", :acceptable_exit_codes => [0,2,4,6])
        sleep(30)
        on(agent, "puppet agent -t --ca_port 8141 --server #{master_fqdn}", :acceptable_exit_codes => [0,2,4,6])
        agent.reboot
        sleep(240)
        on(agent, "puppet agent -t --ca_port 8141 --server #{master_fqdn}", :acceptable_exit_codes => [0,2])
      end
      it 'should be idempotent' do
        sleep(30)
        on(agent, 'puppet agent -t', :acceptable_exit_codes => [0])
      end
    end
  end

end
