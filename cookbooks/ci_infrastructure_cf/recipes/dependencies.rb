include_recipe "rbenv::user_install"
include_recipe "ruby_build"

rbenv_ruby "1.9.3-p194" do
  user 'jenkins'
end

ruby_block  'enable-cli' do
  block do
     path = '/etc/default/jenkins'
     text = File.read(path)
     text.gsub!('JAVA_ARGS=""', 'JAVA_ARGS="-Dhudson.diyChunking=false"')
     File.open(path, 'w') { |f| f.write(text) }
  end
  notifies :restart, 'service[jenkins]', :immediately
  notifies :write, 'log[enable-cli-msg]', :immediately
  not_if {File.exists?('/etc/default/jenkins') &&
          File.read('/etc/default/jenkins').include?('-Dhudson')}

end

log 'enable-cli-msg' do
  message 'enabling cli connections from everywhere'
  action :nothing
end

service 'jenkins' do
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

package 'git'

package 'unzip'

jenkins_plugin 'git-client' do
  action :install
end

jenkins_plugin 'git' do
  notifies :execute, 'jenkins_command[safe-restart]', :immediately
end

jenkins_plugin 'git' do
  action :enable
end

jenkins_command 'safe-restart' do
  action :nothing
  notifies :run, 'execute[wait-for-jenkins]', :immediately
end

execute "wait-for-jenkins" do
  command "sleep 40"
  action :nothing
end

src_filename = "spiff.zip"
src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
extract_path = '/usr/local/bin'

remote_file 'spiff' do
  source node['spiff']['url']
  path src_filepath
  owner 'jenkins'
  group 'jenkins'
  mode "0644"
end

execute 'unzip-spiff' do
  command "unzip -o #{src_filepath} -d #{extract_path} "
end