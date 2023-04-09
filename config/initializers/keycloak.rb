# Set proxy to connect in keycloak server
Keycloak.proxy = ''
# If true, then all request exception will explode in application (this is the default value)
Keycloak.generate_request_exception = true
# controller that manage the user session
Keycloak.keycloak_controller = 'session'
# relm name (only if the installation file is not present)
Keycloak.realm = ''
# relm url (only if the installation file is not present)
Keycloak.auth_server_url = 'https://sso.sota.org.uk/auth/realms/SOTA/protocol/openid-connect/token'
# The introspect of the token will be executed every time the Keycloak::Client.has_role? method is invoked, if this setting is set to true.
Keycloak.validate_token_when_call_has_role = false
