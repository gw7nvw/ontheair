Keycloak::Client.module_eval do
    def self.get_token(user, password, client_id = '', secret = '')
      setup_module
      
      client_id = @client_id if isempty?(client_id)
      secret = @secret if isempty?(secret)
 
      payload = { 'client_id' => client_id,
                  'client_secret' => secret,
                  'username' => user,
                  'password' => password,
                  'grant_type' => 'password',
                  'scope' => 'openid'
      }
      mount_request_token(payload)
    end
end

