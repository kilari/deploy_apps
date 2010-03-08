module SvnAPI

  def self.check_out(options)
    system("/usr/local/bin/svn CO --username #{options[:repo_user]} --password #{options[:repo_pass]} #{options[:co_url]} #{options[:cap_dir]}")
  end
  
end
