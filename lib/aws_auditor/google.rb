require "google/api_client"
require "google_drive"

module AwsAuditor
	class GoogleConfig < Hash
    include Hashie::Extensions::IndifferentAccess
  end

  class Google
    FILE_NAMES = %w[.google.yml]

    def self.configuration
      GoogleDrive.login_with_oauth(get_authorization)
    end

    def self.get_authorization
      creds = load_config[:credentials]
      client = ::Google::APIClient.new
      auth = client.authorization
      auth.client_id = creds[:client_id]
      auth.client_secret = creds[:client_secret]
      auth.scope =
          "https://www.googleapis.com/auth/drive " +
          "https://docs.google.com/feeds/ " +
          "https://docs.googleusercontent.com/ " +
          "https://spreadsheets.google.com/feeds/"
      auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
      print("1. If it doesn't automatically open, open this page:\n%s\n\n" % auth.authorization_uri)
      `open "#{auth.authorization_uri}"`
      print("2. Enter the authorization code shown in the page: ")
      auth.code = $stdin.gets.chomp
      auth.fetch_access_token!
      access_token = auth.access_token
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

