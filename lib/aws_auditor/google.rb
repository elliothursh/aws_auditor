require "google_drive"

module AwsAuditor
	class GoogleConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class Google
    FILE_NAMES = %w[.google.yml]

    def self.configuration
      credentials = load_config[:login]
      GoogleDrive.login(credentials[:email],credentials[:password])
    end

    def self.file
      load_config[:file]
    end

    def self.load_config
      return @config if @config
      @config = GoogleConfig[YAML.load_file(config_path)]
    end

    def self.config_path
      if filepath = FILE_NAMES.detect {|filename| File.exists?(filename)}
        File.join(Dir.pwd, filepath)
      else
        old_dir = Dir.pwd
        Dir.chdir('..')
        if old_dir != Dir.pwd
          config_path
        else
          puts "Could not find #{FILE_NAMES.join(' or ')}"
          exit
        end
      end
    end

  end
end

