Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    # Handle /api/* endpoints
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      max_age: 86400 # Caches the preflight response for 24 hours to boost performance

    # Handle /api2/* endpoints
    resource '/api2/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      max_age: 86400
  end
end
