module Deploy
  class UtilRun
    
    
    def initialize(options,usage)
      @options = options
      if @options[:file]
        OPTIONS.each do |k,v|
          instance_variable_set("@#{k}", v) if v
        end
        @options[:cpanel_user] ||= @cpanel_user
        @options[:cpanel_pass] ||= @cpanel_pass
        @options[:connection_addr] ||= @connection_addr
      end
      @cpanel_api = CpanelDeployApi::Base.new(@options[:cpanel_user],@options[:cpanel_pass],@options[:connection_addr],usage)
    end
   
    def add_db
      @options[:db_name] ||= @db_name
      @options[:db_type] ||= (@db_type||'mysql')
      @cpanel_api.add_db(@options)
    end

    def add_db_user
      @options[:db_name] ||= @db_name
      @options[:db_user] ||= @db_user
      @options[:db_pass] ||= (@db_pass || Deploy.random)
      @options[:db_type] ||= (@db_type||'mysql')
      reply = @cpanel_api.add_db_user(@options)
      puts reply[:status] +"\t"+ reply[:message]
    end

    def list_dbs
      @options[:db_type] ||= (@db_type||'mysql')
      puts @cpanel_api.list_dbs(@options[:db_type])
    end
    
    def list_users
      @options[:db_type] ||= (@db_type||'mysql')
      puts @cpanel_api.list_users(@options[:db_type])
    end
    
    def del_db
      @options[:db_name] ||= @db_name
      @options[:db_type] ||= (@db_type||'mysql')
      reply = @cpanel_api.del_db(@options)
      puts reply[:status] +"\t"+ reply[:message]
    end
    
    def del_user
      @options[:db_user] ||= @db_user
      @options[:db_type] ||= (@db_type||'mysql')
      reply = @cpanel_api.del_user(@options)
      puts reply[:status] +"\t"+ reply[:message]
    end

    def list_domains
      puts @cpanel_api.list_domains
    end

    def list_subdomains
      puts @cpanel_api.list_subdomains
    end

    def add_domain
      @options[:domain] ||= @domain
      @options[:doc_root] ||= @doc_root
      @cpanel_api.add_domain(@options)
    end

    def add_subdomain
      
    end
    
    def park_domain
      @options[:park_domain] ||= @park_domain
      @cpanel_api.park_domain(@options[:park_domain])
    end
    

  end
end
