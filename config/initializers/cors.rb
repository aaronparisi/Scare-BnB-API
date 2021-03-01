Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:8080', 
      'http://localhost:5000'
      # 'https://www.frontend-auth-ca586.firebaseapp.com', 
      # 'http://www.frontend-auth-ca586.firebaseapp.com', 
      # 'https://frontend-auth-ca586.firebaseapp.com', 
      # 'http://frontend-auth-ca586.firebaseapp.com', 
      # 'http://www.frontend-auth.aaronparisidev.com', 
      # 'https://www.frontend-auth.aaronparisidev.com', 
      # 'http://frontend-auth.aaronparisidev.com',
      # 'https://frontend-auth.aaronparisidev.com'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      exposedHeaders: ["Set-Cookie"]
  end
end