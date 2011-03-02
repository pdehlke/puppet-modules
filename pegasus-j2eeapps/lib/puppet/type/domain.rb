Puppet::Type.newtype(:domain) do
  @doc = "Manage Glassfish domains"

  ensurable

  newparam(:name) do
    desc "The Glassfish domain name."
    isnamevar
  end

  newparam(:smf) do
    desc "Create Solaris SMF service. Default: false"
    defaultto false
  end

  newparam(:startoncreate) do
    desc "Start the domain immediately after it is created. Default: true"
    defaultto true
  end

  newparam(:portbase) do
    desc "The Glassfish domain port base. Default: 4800"
    defaultto "4800"
  end

  newparam(:profile) do
    desc "Glassfish domain profile: cluster, devel, etc. Default: cluster"
    defaultto "cluster"
  end

  newparam(:asadminuser) do
    desc "The internal Glassfish user asadmin uses. Default: admin"
    defaultto "admin"
  end

  newparam(:passwordfile) do
    desc "The file containing the password for the user."

    validate do |value|
      unless File.exists? value
        raise ArgumentError, "%s does not exists" % value
      end
    end
  end

    newparam(:path) do                                                                
      desc "The search path used for command execution.                               
        Commands must be fully qualified if no path is specified.  Paths              
        can be specified as an array or as a colon-separated list."                   
                                                                                      
      # Support both arrays and colon-separated fields.                               
      def value=(*values)                                                             
        @value = values.flatten.collect { |val|                                       
          if val =~ /;/ # recognize semi-colon separated paths                        
            val.split(";")                                                            
          elsif val =~ /^\w:[^:]*$/ # heuristic to avoid splitting a driveletter away 
            val                                                                       
          else                                                                        
            val.split(":")                                                            
          end                                                                         
        }.flatten                                                                     
      end                                                                             
    end                                                      

  newparam(:user) do
    desc "The user to run the command as."

    validate do |user|
      unless Puppet.features.root?
        self.fail "Only root can execute commands as other users"
      end
    end
  end
end
