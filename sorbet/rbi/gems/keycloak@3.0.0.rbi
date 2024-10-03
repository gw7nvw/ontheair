# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `keycloak` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Keycloak
  class << self
    def auth_server_url; end
    def auth_server_url=(_); end
    def explode_exception; end
    def generate_request_exception; end
    def generate_request_exception=(_); end
    def generic_request(access_token, uri, query_parameters, body_parameter, method); end
    def installation_file; end
    def installation_file=(file = T.unsafe(nil)); end
    def keycloak_controller; end
    def keycloak_controller=(_); end
    def proc_cookie_token; end
    def proc_cookie_token=(_); end
    def proc_external_attributes; end
    def proc_external_attributes=(_); end
    def proxy; end
    def proxy=(_); end
    def realm; end
    def realm=(_); end
    def rescue_response(response); end
    def validate_token_when_call_has_role; end
    def validate_token_when_call_has_role=(_); end
  end
end

module Keycloak::Admin
  class << self
    def add_client_level_roles_to_user(id, client, role_representation, access_token = T.unsafe(nil)); end
    def base_url; end
    def count_users(access_token = T.unsafe(nil)); end
    def create_user(user_representation, access_token = T.unsafe(nil)); end
    def delete_client_level_roles_from_user(id, client, role_representation, access_token = T.unsafe(nil)); end
    def delete_user(id, access_token = T.unsafe(nil)); end
    def effective_access_token(access_token); end
    def full_url(service); end
    def generic_delete(service, query_parameters = T.unsafe(nil), body_parameter = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def generic_get(service, query_parameters = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def generic_post(service, query_parameters, body_parameter, access_token = T.unsafe(nil)); end
    def generic_put(service, query_parameters, body_parameter, access_token = T.unsafe(nil)); end
    def get_all_roles_client(id, access_token = T.unsafe(nil)); end
    def get_client_level_role_for_user_and_app(id, client, access_token = T.unsafe(nil)); end
    def get_clients(query_parameters = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def get_effective_client_level_role_composite_user(id, client, access_token = T.unsafe(nil)); end
    def get_groups(query_parameters = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def get_role_mappings(id, access_token = T.unsafe(nil)); end
    def get_roles_client_by_name(id, role_name, access_token = T.unsafe(nil)); end
    def get_user(id, access_token = T.unsafe(nil)); end
    def get_users(query_parameters = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def reset_password(id, credential_representation, access_token = T.unsafe(nil)); end
    def revoke_consent_user(id, client_id = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def update_account_email(id, actions, redirect_uri = T.unsafe(nil), client_id = T.unsafe(nil), access_token = T.unsafe(nil)); end
    def update_effective_user_roles(id, client_id, roles_names, access_token = T.unsafe(nil)); end
    def update_user(id, user_representation, access_token = T.unsafe(nil)); end
  end
end

module Keycloak::Client
  class << self
    def auth_server_url; end
    def auth_server_url=(_); end
    def client_id; end
    def configuration; end
    def decoded_access_token(access_token = T.unsafe(nil)); end
    def decoded_id_token(idToken = T.unsafe(nil)); end
    def decoded_refresh_token(refresh_token = T.unsafe(nil)); end
    def exec_request(proc_request); end
    def external_attributes; end
    def get_attribute(attributeName, access_token = T.unsafe(nil)); end
    def get_installation; end
    def get_token(user, password, client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_token_by_client_credentials(client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_token_by_code(code, redirect_uri, client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_token_by_exchange(issuer, issuer_token, client_id = T.unsafe(nil), secret = T.unsafe(nil), token_endpoint = T.unsafe(nil)); end
    def get_token_by_refresh_token(refresh_token = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_token_introspection(token = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil), token_introspection_endpoint = T.unsafe(nil)); end
    def get_userinfo(access_token = T.unsafe(nil), userinfo_endpoint = T.unsafe(nil)); end
    def get_userinfo_issuer(access_token = T.unsafe(nil), userinfo_endpoint = T.unsafe(nil)); end
    def has_role?(user_role, access_token = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil), token_introspection_endpoint = T.unsafe(nil)); end
    def logout(redirect_uri = T.unsafe(nil), refresh_token = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil), end_session_endpoint = T.unsafe(nil)); end
    def mount_request_token(payload); end
    def openid_configuration; end
    def public_key; end
    def realm; end
    def realm=(_); end
    def secret; end
    def setup_module; end
    def token; end
    def url_login_redirect(redirect_uri, response_type = T.unsafe(nil), client_id = T.unsafe(nil), authorization_endpoint = T.unsafe(nil)); end
    def url_user_account; end
    def user_signed_in?(access_token = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil), token_introspection_endpoint = T.unsafe(nil)); end
    def verify_setup; end
  end
end

Keycloak::Client::KEYCLOACK_CONTROLLER_DEFAULT = T.let(T.unsafe(nil), String)

class Keycloak::InstallationFileNotFound < ::Keycloak::KeycloakException
end

module Keycloak::Internal
  include(::Keycloak::Admin)

  class << self
    def change_password(user_id, redirect_uri = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def create_simple_user(username, password, email, first_name, last_name, realm_roles_names, client_roles_names, proc = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def create_starter_user(username, password, email, client_roles_names, proc = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def default_call(proc, client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def exists_name_or_email(value, user_id = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def forgot_password(user_login, redirect_uri = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_client_roles(client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_client_user_roles(user_id, client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_groups(query_parameters = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_logged_user_info(client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_user_info(user_login, whole_word = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def get_users(query_parameters = T.unsafe(nil), client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def has_role?(user_id, user_role, client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
    def logged_federation_user?(client_id = T.unsafe(nil), secret = T.unsafe(nil)); end
  end
end

Keycloak::KEYCLOAK_JSON_FILE = T.let(T.unsafe(nil), String)

class Keycloak::KeycloakException < ::StandardError
end

Keycloak::OLD_KEYCLOAK_JSON_FILE = T.let(T.unsafe(nil), String)

class Keycloak::ProcCookieTokenNotDefined < ::Keycloak::KeycloakException
end

class Keycloak::ProcExternalAttributesNotDefined < ::Keycloak::KeycloakException
end

class Keycloak::UserLoginNotFound < ::Keycloak::KeycloakException
end

Keycloak::VERSION = T.let(T.unsafe(nil), String)