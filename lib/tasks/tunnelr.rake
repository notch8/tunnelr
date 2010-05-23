# Taken from the Facebooker plugin, because with all the oauth going around we need it everywhere these days

# Courtesy of Christopher Haupt
# http://www.BuildingWebApps.com
# http://www.LearningRails.com

require 'fileutils'

tunnel_ns = namespace :tunnelr do

  desc "Create a basic tunnelr.yml configuration file"
  task :setup => :environment do   
    tunnelr_config = File.join(RAILS_ROOT,"config","tunnelr.yml")
    unless File.exist?(tunnelr_config)
      plugin_root = File.join(RAILS_ROOT,"vendor","plugins")
      tunnelr_config_tpl = File.join(plugin_root,"tunnelr","generators","tunnelr","templates","config","tunnelr.yml")
      FileUtils.cp tunnelr_config_tpl, tunnelr_config 
      puts "Ensure 'GatewayPorts yes' is enabled in the remote development server's sshd config when using any of the tunnelr:*' rake tasks"
      puts "Configuration created in #{RAILS_ROOT}/config/tunnelr.yml"
    else
      puts "#{RAILS_ROOT}/config/tunnelr.yml already exists"
    end
  end

  desc "Create a reverse ssh tunnel from a public server to a private development server." 
  task :start => [ :environment, :config ] do  
    puts @notification 
    system @ssh_command
  end 

  desc "Create a reverse ssh tunnel in the background. Requires ssh keys to be setup." 
  task :background_start => [ :environment, :config ] do  
    puts @notification 
    system "#{@ssh_command} > /dev/null 2>&1 &" 
  end 

  # Adapted from Evan Weaver: http://blog.evanweaver.com/articles/2007/07/13/developing-a-facebook-app-locally/ 
  desc "Check if reverse tunnel is running"
  task :status => [ :environment, :config ] do
   if `ssh #{@public_host} -l #{@public_host_username} netstat -an | egrep "tcp.*:#{@public_port}.*LISTEN" | wc`.to_i > 0
     puts "Seems ok"
   else
     puts "Down"
   end
  end
  
  task :config => :environment do
   tunnelr_config = File.join(RAILS_ROOT, 'config', 'tunnelr.yml')
   TUNNELR = YAML.load(ERB.new(File.read(tunnelr_config)).result)[RAILS_ENV]
   @public_host_username = TUNNELR['public_host_username'] 
   @public_host = TUNNELR['public_host'] 
   @public_port = TUNNELR['public_port'] 
   @local_port = TUNNELR['local_port'] 
   @ssh_port = TUNNELR['ssh_port'] || 22
   @server_alive_interval = TUNNELR['server_alive_interval'] || 0
   @notification = "Starting tunnel #{@public_host}:#{@public_port} to 0.0.0.0:#{@local_port}"
   @notification << " using SSH port #{@ssh_port}" unless @ssh_port == 22
   # "GatewayPorts yes" needs to be enabled in the remote's sshd config
   @ssh_command = %Q[ssh -v -p #{@ssh_port} -nNT4 -o "ServerAliveInterval #{@server_alive_interval}" -R *:#{@public_port}:localhost:#{@local_port} #{@public_host_username}@#{@public_host}]
  end
 
end

desc "Create a reverse ssh tunnel from a public server to a private development server."
task :tunnelr => tunnel_ns[:start]