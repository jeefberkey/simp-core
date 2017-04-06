require 'spec_helper_integration'
require 'erb'

test_name 'puppetserver via rpm'

# Find a release tarball
def find_tarball
  tarball = ENV['BEAKER_release_tarball']
  tarball ||= Dir.glob('spec/fixtures/SIMP*.tar.gz')[0]
  warn("Found Tarball: #{tarball}")
  tarball
end

def tarball_yumrepos(tarball)
  master.install_package('createrepo')
  scp_to(master, tarball, '/root/')
  tarball_basename = File.basename(tarball)
  on(master, "mkdir -p /var/www && cd /var/www && tar xzf /root/#{tarball_basename}")
  on(master, 'createrepo -q -p /var/www/SIMP/noarch')
  create_remote_file(master, '/etc/yum.repos.d/simp_tarball.repo', <<-EOF.gsub(/^\s+/,'')
    [simp-tarball]
    name=Tarball repo
    baseurl=file:///var/www/SIMP/noarch
    enabled=1
    gpgcheck=0
    repo_gpgcheck=0
    EOF
  )
  on(master, 'yum makecache')
end

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
      master.install_package('epel-release')
      # master.install_package('https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-3.noarch.rpm')
      on(host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X_Dependencies/script.rpm.sh | bash')

      tarball = find_tarball
      if tarball.nil? or tarball.empty?
        warn('='*72)
        warn('Using Internet repos from packagecloud for testing')
        warn('Specify a tarball with BEAKER_release_tarball or by placing one in spec/fixtures')
        warn('='*72)
        on(host, 'curl -s https://packagecloud.io/install/repositories/simp-project/6_X/script.rpm.sh | bash')
      else
        warn('='*72)
        warn("Found Tarball: #{tarball}")
        warn('Test will continue by setting up a local repository on the master from the tarball')
        warn('='*72)
        tarball_yumrepos(tarball)
      end
      on(master, 'yum makecache')
    end
  end

  context 'master' do
    let(:simp_conf_template) { File.read(File.open('spec/acceptance/suites/rpm/files/simp_conf.yaml.erb')) }
    masters.each do |master|
      it 'should install simp' do
        master.install_package('simp-adapter-foss')
        master.install_package('simp')
      end
      it 'should run simp config' do
        # grub password: H.SxdcuyF56G75*3ww*HF#9i-eDM3Dp5
        # ldap root password: Q*AsdtFlHSLp%Q3tsSEc3vFbFx5Vwe58
        create_remote_file(master, '/root/simp_conf.yaml', ERB.new(simp_conf_template).result(binding))
        # require 'pry';binding.pry
        on(master, 'simp config -a /root/simp_conf.yaml --quiet')
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

          classes:
            - simp::yum::repos::internet_simp_dependencies
          EOF
        )
      end
      it 'should enable autosign' do
        on(master, 'puppet config --section master set autosign true')
      end
      it 'should run simp bootstrap' do
        # this makes me sad but I am unsure of how to fix it for now
        on(master, 'simp bootstrap --no-verbose -u --remove_ssldir > /dev/null', :accept_all_exit_codes => true)
        on(master, 'simp bootstrap --no-verbose -u --remove_ssldir > /dev/null')
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0,2,4,6])
      end
      it 'should reboot the host' do
        master.reboot
        sleep(240)
      end
      it 'should have puppet runs with no changes' do
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0,2,4,6])
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0,2] )
        on(master, 'puppet agent -t', :acceptable_exit_codes => [0] )
      end
      it 'should generate agent certs' do
        pending
        togen = []
        agents.each do |agent|
          togen << agent.hostname
        end
        create_remote_file(master, '/var/simp/environments/simp/FakeCA/togen', togen.join("\n"))
        on(master, 'cd /var/simp/environments/simp/FakeCA; ./gencerts_nopass')
      end
    end
  end

  # context 'classify nodes' do
  # end

  context 'agents' do
    agents.each do |agent|
      it 'should run the agent' do
        # require 'pry';binding.pry if fact_on(agent, 'hostname') == 'agent'
        on(agent, "puppet agent -t --ca_port 8141 --masterport 8141 --server #{master_fqdn} --tags pupmod,simp", :acceptable_exit_codes => [0,2,4,6])
        on(agent, 'puppet agent -t', :acceptable_exit_codes => [0,2,4,6])
        agent.reboot
        sleep(240)
        on(agent, 'puppet agent -t', :acceptable_exit_codes => [0,2])
      end
      it 'should be idempotent' do
        sleep(30)
        on(agent, 'puppet agent -t', :acceptable_exit_codes => [0])
      end
    end
  end

end
