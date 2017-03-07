module SportNginAwsAuditor
  module GoogleWrapper
    attr_accessor :google

    def google
      @google ||= SportNginAwsAuditor::Google.configuration
    end
  end
  
end
