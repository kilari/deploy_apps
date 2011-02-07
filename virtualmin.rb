#require 'logger'
module Deploy
  
  class Virtualmin

    V_COMMAND = '/usr/sbin/virtualmin'
    #attr_accessor :user, :domain_name, :db_name, :db_type, :pass

 #   def initialize #(domain_name = nil,user = nil,db_name = nil,db_type = nil,pass = nil)
 #     @log = Logger.new('deploy.log')
 #     @log.datetime_format = "%H:%M:%S"
 #   end

    def run_cmd?(cmd,options = '')
      system(V_COMMAND + ' ' + cmd + ' ' + options + ' > deploy.log')
      true if $?.exitstatus == 0
    end
  
    def run_cmd(cmd,options = '')
      #%x[#{V_COMMAND} #{cmd + ' ' + options}]
      system(V_COMMAND + ' ' + cmd + ' ' + options)
      #true if $?.exitstatus == 0
    end
  
    def random(n=20)
      a = ('a'..'z').to_a
      pass = ''
      n.times{ pass<<a[rand(a.length-1)]}
      pass
    end  

    def main_user(domain_name)
      (run_cmd 'list-domains', "--domain #{domain_name}").to_a[2].split[1]  if is_domain? domain_name
    end

    def is_domain?(domain_name)
      run_cmd? 'list-domains', "--domain #{domain_name}"
    end

    def is_db?(domain_name,db_name)
      run_cmd? 'list-databases', "--domain #{domain_name} --name-only | grep -e ^#{db_name}$"
    end

    def is_user?(domain_name,db_user)
      run_cmd? 'list-users', "--domain #{domain_name} --name-only | grep -e ^#{db_user}.#{main_user domain_name }"
    end
  
    def create_server(domain_name,pass)
      #run_cmd? 'create-domain', "--domain #{@domain_name} --user #{@user} --pass #{@pass} --unix --dir --web --mail --spam --virus --virtualmin-awstats --webmin --webalizer --logrotate --ftp --ssl --skip-warnings --quota UNLIMITED --uquota UNLIMITED"
      run_cmd? 'create-domain', "--domain #{domain_name} --pass #{pass} --unix --dir --web --mysql --mail --spam --virus --virtualmin-awstats --webmin --webalizer --logrotate --ssl --skip-warnings"
      #run_cmd 'enable-feature', "--domain #{domain_name} --mysql"
    end

    def del_server(domain_name)
      if is_domain?(domain_name)
        run_cmd 'delete-domain', "--domain #{domain_name}"
      end
    end

    def create_db(domain_name,db_name,db_type = 'mysql')
      #need to add --mysql to the server again if any chance
      run_cmd 'create-database', "--domain #{domain_name} --name #{db_name} --type #{db_type}"
    end  
  
    def del_db(domain_name,db_name,db_type = 'mysql')
      if is_db?(domain_name,db_name)
        run_cmd 'delete-database', "--domain #{domain_name} --name #{db_name} --type #{db_type}"
      end
    end
  
    def create_user(domain_name,db_name, db_user, db_pass)
      run_cmd 'create-user', "--domain #{domain_name} --user #{db_user} --pass #{db_pass} --mysql #{db_name} --noemail"
    end

    def del_user(domain_name,db_name, db_user)
      if is_user? domain_name,db_user
        run_cmd 'delete-user', "--domain #{domain_name} --user #{db_user}"
      end
    end

    def assign_user
      if is_user? domain_name,db_user
         run_cmd 'modify-user', ""
      end
    end
      


    private :run_cmd?, :run_cmd

  end
end

