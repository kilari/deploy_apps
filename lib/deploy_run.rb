module Deploy
  class DeployRun
    
    def initialize(usage)
      @options = {}
      abort "No settings files found in the current directory." unless OPTIONS
      OPTIONS.each do |k,v|
        @options[:"#{k}"] = "#{v}" unless v.nil?
      end
      check_imp_data
      @options[:scm_type] ||= 'git'
      @options[:scm_type] = @options[:scm_type].downcase
      @options[:db_type] ||= :mysql 
      @options[:deploy_path] ||= "/home/#{@options[:cpanel_user]}/deployed_apps/#{@options[:domain]}/#{@options[:app_name]}"
      @options[:cap_dir] ||= "/home/#{(`whoami`).chomp}/deploy/#{@options[:app_name]}"
      @options[:doc_root] ||= @options[:deploy_path] + '/public'
      @options[:env] ||= :production
      @options[:server_type] ||= :passenger
      @cpanel_api = CpanelDeployApi::Base.new(@options[:cpanel_user],@options[:cpanel_pass],@options[:connection_addr],usage)
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
      if File.directory?(@options[:cap_dir])
        if File.exists?(@options[:cap_dir] + '/config/environment.rb')
          if system("capify #{@options[:cap_dir]}")
            puts "Capifyed the application, now cap deploy:setup then cap deploy"
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
      @options[:db_name] ||= @options[:app_name] + "#{rand(200)}"
      reply = @cpanel_api.add_db(@options)
      @options[:f_db_name] =  reply[:db]
    end
    
    def check_db_user
      @options[:db_user] ||= (@options[:db_name].size>7? @options[:db_name][0,6]:@options[:db_name])
      @options[:db_pass] ||= Deploy.random(10)
      reply = @cpanel_api.add_db_user(@options)
      @options[:f_db_user] = reply[:user]
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
      puts "**********************************"
    end
    
    def puts_deploy_file
      dep = File.read(File.dirname(__FILE__) + '/../template/deploy.rb.erb')
      @deploy_file = ERB.new(dep).result(binding)
      puts "**************************************************************"
      puts "*                       deploy.rb file                       *"
      puts "**************************************************************"
      puts @deploy_file
      puts "**************************************************************"
    end
    
    def add_deploy_file
      sample = File.open( "#{@options[:cap_dir]}/config/deploy.rb", 'w')
      sample.pos = 0
      sample.print @deploy_file
      sample.close
    end
    
    def main_check
     check_domain
     check_db 
     check_db_user 
     check_local_doc_root  
     fix_doc_root
     puts_db_details
     puts_deploy_file
     add_deploy_file
    end
    
    def askq
      ask("Do you want to enter now? Y or N"){|q| q.validate = /[Yy]|[Nn]/}
    end
    
  end
end