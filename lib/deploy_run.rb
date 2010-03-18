module Deploy
  class DeployRun
    
    def initialize(usage)
      @options = {}
      abort "No settings files found in the current directory. Pass -g option to generate a settings.yml." unless OPTIONS
      OPTIONS.each do |k,v|
        @options[:"#{k}"] = v if v
      end
      check_imp_data
      @options[:scm_type] ||= 'git'
      @options[:scm_type] = @options[:scm_type].downcase
      @options[:db_type] ||= 'mysql' 
      @options[:deploy_path] ||= "/home/#{@options[:cpanel_user]}/deployed_apps/#{@options[:domain]}/#{@options[:app_name]}"
      @options[:cap_dir] ||= "/home/#{(`whoami`).chomp}/deploy/#{@options[:app_name]}"
      @options[:doc_root] ||= @options[:deploy_path] + '/public'
      @options[:env] ||= :production
      @options[:server_type] ||= :passenger
      @cpanel_api = CpanelDeployApi::Base.new(@options[:cpanel_user],@options[:cpanel_pass],@options[:connection_addr],usage)
      HighLine.track_eof = false
    end
    
    def check_imp_data
      unless @options[:domain]
        puts "Domain name can not be left blank."
        @options[:domain] = ask("Enter the domain name now.")
      end
      unless @options[:app_name]
        puts "Application name can not be left blank."
        @options[:app_name] = ask("Enter the application name now.")
      end  
      
      unless @options[:co_url]
        puts "Repository URL can not be left blank."
        @options[:co_url] = ask("Enter the repository URL now.")
      end
    end  
    
    def check_local_doc_root
      require 'capistrano'
      if File.directory?(@options[:cap_dir])
        if File.exists?(@options[:cap_dir] + '/config/environment.rb')
          if system("capify #{@options[:cap_dir]}")
            fix_doc_root
            puts_db_details if (@options[:f_db_name] && @options[:f_db_user] && @options[:db_pass])
            puts_deploy_file
            add_deploy_file
            puts "*********************************************************************************************************************"
            puts "*Capifyed the application at #{@options[:cap_dir]}, now \'cap deploy:setup\' then \'cap deploy\' from that directory*"
            puts "*********************************************************************************************************************\n"
          else
            puts "Could not find capify command!"
          end
        else
          (puts "The Repository apps also doesn't seems to be a valid rails apps." && return) if @count == 1
          puts "The folder doesn't seems to be a Rails application, moving it and checking out he apps frm the repository."
          system("mv #{@options[:cap_dir]} #{@options[:cap_dir]}.bkup")
          @count = 1
          check_out
        end
      else
        puts "Couldn't find the application, downloading it from the repository"
        check_out
      end
    rescue LoadError
      puts "\n** Could not find the capistrano gem,you will need to install the capistrano gem using the command \'gem install capistrano\'"
    end
    
    def check_out
      if @options[:scm_type] == 'git'
        GitAPI.check_out(@options)
      elsif @options[:scm_type] == 'svn'
        unless (@options[:repo_user] && @options[:repo_pass])
          puts "Enter the repository User name and pass"  
          @options[:repo_user] = ask("Enter the Repository User:")
          @options[:repo_pass] = ask("Enter the Repository password for the above user:")
          SvnAPI.check_out(@options)
        else
          SvnAPI.check_out(@options)
        end  
      else
        puts "Only Git and SVN supported."
        return
      end
      check_local_doc_root
    end
    
    def check_domain
      if @cpanel_api.is_domain?(@options[:domain])
        puts "Domain #{@options[:domain]} already added to your cPanel."
        @options[:doc_root] =  @cpanel_api.get_doc_root(@options[:domain])
      else
        reply = @cpanel_api.add_domain(@options)
      end  
    end
    
    def check_db
      unless @options[:db_name]
        choice = %w{add_a_Database_with_a_random_name enter_the_Database_name exit}
        say("\n\nNo Database name found!!")
        choose do |menu|
          menu.prompt = "Choose what to do now?"
          menu.choice :add_a_Database_with_a_random_name do
            count = 0
            loop do
              count += 1
              @options[:db_name] = @options[:app_name] + "#{rand(200)}"
              break if count == 4
              next if @cpanel_api.is_db?(@options)
              reply = @cpanel_api.add_db(@options)
              ((@options[:f_db_name] =  reply[:db]) && break) if reply[:status] == 'true'
            end  
          end
          menu.choice :enter_the_Database_name do
            loop do
              @options[:db_name] = ask("\n\nEnter the database name now.")
              if @cpanel_api.is_db?(@options)
                puts "\n\nDatabase already exists."
              else  
                reply = @cpanel_api.add_db(@options)
                ((@options[:f_db_name] =  reply[:db]) && break) if reply[:status] == 'true'
              end
            end  
          end
          menu.choice(:exit) do
            say("Database settings not added.") 
          end
        end
      else
        if @cpanel_api.is_db?(@options)
          choice = %w{use_it add_new}
          say("\n\nDatabase already present,use it(make sure no other apps is using it) or add a new db?")
          choose do |menu|
            menu.prompt = "Choose what to do now?"
            menu.choice :use_it do
              @options[:f_db_name] =  @cpanel_api.add_cpanel_user_name(@options[:db_name])
            end
            menu.choice :add_new do
              @options[:db_name] = nil
              check_db
            end
          end
        else
          reply = @cpanel_api.add_db(@options)
          @options[:f_db_name] =  reply[:db]
        end
      end
    end
    
    def check_db_user
      @options[:db_pass] ||= Deploy.random(10)
      unless @options[:db_user]
        choice = %w{add_a_user_with_a_random_name enter_the_username exit}
        say("\n\nNo User name found!!")
        choose do |menu|
          menu.prompt = "Choose what to do now?"
          menu.choice :add_a_user_with_a_random_name do
            count = 0
            loop do
              count += 1
              @options[:db_user] = @options[:db_name][0,3] + "#{rand(999)}"
              break if count == 4
              next if @cpanel_api.is_user?(@options)
              reply = @cpanel_api.add_db_user(@options)
              ((@options[:f_db_user] =  reply[:user]) && break) if reply[:status] == 'true'
            end  
          end
          menu.choice :enter_the_username do
            loop do
              @options[:db_user] = ask("\n\nEnter the User name now.")
              if @cpanel_api.is_user?(@options)
                puts "\n\nUser already exists."
              else  
                reply = @cpanel_api.add_db_user(@options)
                ((@options[:f_db_user] =  reply[:user]) && break) if reply[:status] == 'true'
              end
            end  
          end
          menu.choice(:exit) do
            say("Database user settings not added.") 
          end
        end
      else
        if @cpanel_api.is_user?(@options)
          choice = %w{use_it add_new}
          say("\n\nUser already present,reset the password and use it or add a new db?")
          choose do |menu|
            menu.prompt = "Choose what to do now?"
            menu.choice :use_it do
              reply = @cpanel_api.add_db_user(@options)
              @options[:f_db_user] = reply[:user]
              #@options[:f_db_user] =  @cpanel_api.add_cpanel_user_name(@options[:db_user])
            end
            menu.choice :add_new do
              @options[:db_user] = nil
              check_db_user
            end
          end
        else
          reply = @cpanel_api.add_db_user(@options)
          @options[:f_db_user] = reply[:user]
        end
      end
    end
    
    def fix_doc_root
      unless @options[:doc_root] == @options[:deploy_path] + '/current/public'
        @fix = "mv #{@options[:doc_root]} #{@options[:doc_root]}.bkup"
        @fix1 = "ln -s #{@options[:deploy_path] + '/current/public'} #{@options[:doc_root]}"
      end
    end
    
    def puts_db_details
      db = File.read(File.dirname(__FILE__) + '/../template/database.erb')
      @db_details = ERB.new(db).result(binding)
      puts "**********************************"
      puts "*DATBASE setting for database.yml*"
      puts "**********************************"
      puts @db_details
      puts "**********************************\n"
    end
    
    def puts_deploy_file
      dep = File.read(File.dirname(__FILE__) + '/../template/deploy.rb.erb')
      @deploy_file = ERB.new(dep).result(binding)
      puts "**************************************************************"
      puts "*                       deploy.rb file                       *"
      puts "**************************************************************"
      puts @deploy_file
      puts "**************************************************************\n"
    end
    
    def add_deploy_file
      sample = File.open( "#{@options[:cap_dir]}/config/deploy.rb", 'w')
      sample.pos = 0
      sample.print @deploy_file
      sample.close
    end
    
    def main_check
    # check_domain
     #check_db 
     #puts @options[:db_name],@options[:f_db_name]
     check_db_user
     puts @options[:db_user],@options[:db_pass],@options[:f_db_user]
    # check_local_doc_root  
    end
    
    def askq
      ask("Do you want to enter now? Y or N")do |q|
        q.validate = /[Yy]|[Nn]/
        q.responses[:not_valid] = "Enter Y or N."
      end
    end
    
  end
end