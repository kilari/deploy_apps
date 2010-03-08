module GitAPI
  
  def self.check_out(options)
    unless options[:repo_user]
      system("git clone #{options[:co_url]} #{options[:cap_dir]}")
    else
      system("git clone #{options[:co_url]} #{options[:cap_dir]}")
    end  
  end
  
  
end