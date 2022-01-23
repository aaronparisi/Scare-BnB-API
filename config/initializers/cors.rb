# Rails.application.config.middleware.insert_before 0, Rack::Cors do
# Rails.application.config.middleware.insert_before ActionDispatch::Static, Rack::Cors do
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Cors do
  allow do
    origins 'http://localhost:8080',
      'https://localhost:8080',
      'http://localhost:5000',
      'https://localhost:5000',
      'https://springfield-bnb.aaronparisi.dev',
      'http://springfield-bnb.aaronparisi.dev',
      'https://www.springfield-bnb.aaronparisi.dev',
      'http://www.springfield-bnb.aaronparisi.dev'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      exposedHeaders: ["Set-Cookie"]
  end
end