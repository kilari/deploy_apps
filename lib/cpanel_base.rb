require File.dirname(__FILE__) + '/cpanel.rb/cpanel'

module CpanelDeployApi

  class Base
     
    def initialize(user,pass,connection_addr,usage)
      @cpanel = Cpanel.new(user,pass,connection_addr)
      @usage = usage.to_s
    end
  
    def add_db(options)
      abort  "Database name not passed.\n#{@usage}" unless options[:db_name]
      set_db_type(options[:db_type])
      reply = @cpanel.create_db(options[:db_name])
      puts reply[:status] +"\t"+ reply[:message]
      reply
    end
  
    def add_db_user(options)
      abort  "Database User not passed\n#{@usage}" unless options[:db_user]
      set_db_type(options[:db_type])
      if options[:db_name].nil?
        if @cpanel.is_user?(options[:db_user])
          puts "User already present. Resetting the password for it."
          @cpanel.reset_user_pass(options[:db_user],options[:db_pass])
        else
          @cpanel.create_db_user(options[:db_user],options[:db_pass])
        end
      else
        if @cpanel.is_user?(options[:db_user])
          puts "User already present. Resetting the password for it."
          reply = @cpanel.reset_user_pass(options[:db_user],options[:db_pass])
          puts reply[:status] +"\t"+ reply[:message]
          if reply[:status]
            @cpanel.assign_user2db(options[:db_name],options[:db_user])
          else
            abort reply[:message]
          end
        else
          reply = @cpanel.create_db_user(options[:db_user],options[:db_pass])
          puts reply[:status] +"\t"+ reply[:message]
          if reply[:status]
            @cpanel.assign_user2db(options[:db_name],options[:db_user])
          else 
            abort reply[:message]
          end  
         end
      end
     
    end
  
    def list_dbs(db_type)
      set_db_type(db_type)
      @cpanel.list_dbs
    end
  
    def list_users(db_type)
      set_db_type(db_type)
      @cpanel.list_db_users
    end
  
    def is_db?(options)
      set_db_type(options[:db_type])
      @cpanel.is_db?(options[:db_name])
    end
    
    def is_user?(options)
      set_db_type(options[:db_type])
      @cpanel.is_user?(options[:db_user])
    end
  
    def del_db(options)
      abort "Database name not passed.\n#{@usage}" unless options[:db_name]
      set_db_type(options[:db_type])
      @cpanel.del_db(options[:db_name])
    end
  
    def del_user(options)
      abort "Database User not passed\n#{@usage}" unless options[:db_user]
      set_db_type(options[:db_type])
      @cpanel.del_user(options[:db_user])
    end
    
    def set_db_type(db_type)
      @cpanel.db_type=db_type
    end
    
    def add_cpanel_user_name(name)
      @cpanel.send(:add_cpanel_user_name,name)
    end
    
    def list_domains
      @cpanel.list_domains
    end
    
    def list_subdomains
      @cpanel.list_sub_domains
    end
    
    def get_doc_root(domain)
      @cpanel.get_doc_root(domain)
    end
    
    def is_domain?(domain)
      @cpanel.list_domains.include?(domain) || @cpanel.list_sub_domains.include?(domain) 
    end
    
    def add_domain(options)
      abort "Domain name not passed\n#{@usage}" unless options[:domain]
      unless options[:doc_root]
        @reply = @cpanel.add_addon_domain(options[:domain])
      else
        @reply = @cpanel.add_addon_domain(options[:domain],options[:doc_root])
      end  
      puts @reply[:status] +"\t"+ @reply[:message]
    end
    
    def add_subdomain(options)
      
    end
    
    def park_domain(domain)
      abort  "Domain name not passed.\n#{@usage}" unless options[:db_name]
      reply = @cpanel.park_domain(domain)
      puts reply[:status] +"\t"+ reply[:message]
    end
    
     
end

end
