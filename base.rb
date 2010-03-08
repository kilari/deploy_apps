#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'
require 'yaml'
require 'highline/import'
load File.dirname(__FILE__) + '/lib/util_run.rb'
load File.dirname(__FILE__) + '/lib/deploy_run.rb'
load File.dirname(__FILE__) + '/lib/cpanel_base.rb'
load File.dirname(__FILE__) + '/lib/git.rb'
require 'ruby-debug'


module Deploy
  
  OPTIONS = YAML.load_file('settings.yml') rescue nil
  #debugger
  class Base
    
    COMMANDS = %W{add_db\n add_db_user\n list_dbs\n list_users\n del_db\n del_user\n
                  list_domains\n list_subdomains\n add_domain\n add_subdomain\n park_domain\n
                  setup_cap\n }
                     
    ABORT_MSG=%{Command not found
    
Available commands:
-----------\n
#{COMMANDS}
-----------\n
More help using #{$0} COMMAND --help}

    
    class <<self
    
      def check_command(command)  
        options,usage = []
        COMMANDS[0..11].each do |name|
          if command == name
            m_name = 'parse_' + name + '_options'
            options,usage = send(m_name)
          end
          break if command == name
        end
        unless options
          abort ABORT_MSG
        else
          [options,usage]
        end
      end
  
      COMMANDS[0..11].each do |name|
        m_name=('parse_' + name.chomp! + '_options')
        send :define_method, m_name do
          options = Hash.new
          ops = OptionParser.new do |opts|
            opts.banner = "Usage: #{$0} COMMAND OPTIONS"
            opts.separator("--------------------------------------------------------------------------")
            opts.separator("COMMAND: #{name}")
            opts.separator("OPTIONS: ")
            if COMMANDS[0..10].include? name
              opts.on("--cpanel-user Cpanel UserName","Cpanel UserName"){|n| options[:cpanel_user]=n}
              opts.on("--cpanel-pass Cpanel Password","Cpanel Password"){|n| options[:cpanel_pass]=n}
              opts.on("--server Cpanel Server IP/domain name","Server IP or domain name if pointing to the server"){|n| options[:connection_addr]=n}
            else
              opts.separator("\nOPTIONS for this are directly taken from the settings.yml file present in the current directory")
            end
            opts.on("--db-name DB NAME","Database name with or without cPanel username"){|n| options[:db_name] = n }   if (name == COMMANDS[0] || name == COMMANDS[4])
            opts.on("--db-user DB USER NAME","Database name with or without cPanel username"){|n| options[:db_user] = n}  if (name == COMMANDS[1] || name == COMMANDS[5])
            opts.on("--db-pass DB USER PASS","[Optional]Password for the user.If not passed a random one will be generated."){|n| options[:db_pass] = n} if name == COMMANDS[1]
            opts.on("--db-type DB TYPE","[Optional]Database type mysql/psql.Defaults to mysql"){|n| options[:db_type] = n} if COMMANDS[0..5].include? name
            opts.on("--assign-to DB NAME","[Optional]Database name with or without cPanel username to assign this user with"){|n| options[:db_name] = n}   if name == COMMANDS[1]
            opts.on("--domain Domain name","Domain name to add"){|n| options[:domain] = n} if name == COMMANDS[8]
            opts.on("--doc-root Document Root","Document root"){|n| options[:doc_root] = n} if name == COMMANDS[8]
            opts.on("--ftp-user FTP UserName","FTP username"){|n| options[:ftp_user] = n} if name == COMMANDS[8]
            opts.on("--ftp-pass FTP Password","FTP Password"){|n| options[:ftp_pass] = n} if name == COMMANDS[8]
            opts.on("-f","--file","Take data from settings.yml file"){options[:file]=true} if COMMANDS[0..10].include? name
            opts.on("-g","--generate","To generate a sample settings.yml file."){options[:sample_file] = true}
            opts.separator("--------------------------------------------------------------------------")
          end  
          ops.parse! ARGV
          [options,ops]
        end
      end
    
      def dispatch_user_input
        command = (((ARGV.shift).dup).downcase) rescue nil
        if command
          options,usage = check_command(command)
          if options[:sample_file]
            sample_temp = File.read(File.dirname(__FILE__) + '/template/settings.yml')
            sample = File.open('settings.yml', 'w')
            sample.pos = 0
            sample.print sample_temp
            sample.close
            puts "Generated a settings.yml in the current directory."
            return
          end  
          if command == 'setup_cap'
            run = DeployRun.new(usage)
            run.main_check
          else
            run = UtilRun.new(options,usage)
            run.send(command)
          end
        else
          puts ABORT_MSG
        end
      end
    
    end  
  
  end

  def self.random(n=20)
    a = ('a'..'z').to_a
    pass = ''
    n.times{ pass<<a[rand(a.length-1)]}
    pass
  end

end   

Deploy::Base.dispatch_user_input
