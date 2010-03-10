module SvnAPI

  def self.check_out(options)
    system("/usr/local/bin/svn CO --username #{options[:repo_user]} --password #{options[:repo_pass]} #{options[:co_url]} #{options[:cap_dir]}")
  end
  
end

module GitAPI
  
  def self.check_out(options)
    unless options[:repo_user]
      system("git clone #{options[:co_url]} #{options[:cap_dir]}")
    else
      system("git clone #{options[:co_url]} #{options[:cap_dir]}")
    end  
  end
  
end