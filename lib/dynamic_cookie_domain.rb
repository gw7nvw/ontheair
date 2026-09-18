# lib/dynamic_cookie_domain.rb
class DynamicCookieDomain
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Determine the correct domain based on the request host
    domain_to_set = if request.host.end_with?('ontheair.nz')
      '.ontheair.nz'
    elsif request.host.end_with?('parksnpeaks.org')
      '.parksnpeaks.org'
    else
      :all
    end

    # Apply to the session options hash if Rails has created it yet
    if env['rack.session.options']
      env['rack.session.options'][:domain] = domain_to_set
    end

    # Also apply to the cookie jar options for ActionDispatch
    env['rack.cookie_options'] ||= {}
    env['rack.cookie_options'][:domain] = domain_to_set

    @app.call(env)
  end
end

