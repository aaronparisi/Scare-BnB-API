# Rails.application.config.middleware.insert_before 0, Rack::Cors do
Rails.application.config.middleware.insert_before ActionDispatch::Static, Rack::Cors do
  allow do
    origins 'http://localhost:8080', 
      'http://localhost:5000',
      'http://localhost:8000',
      'https://springfield-bnb.aaronparisidev.com',
      'http://springfield-bnb.aaronparisidev.com',
      'https://www.springfield-bnb.aaronparisidev.com',
      'http://www.springfield-bnb.aaronparisidev.com'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      exposedHeaders: ["Set-Cookie"]
  end
end