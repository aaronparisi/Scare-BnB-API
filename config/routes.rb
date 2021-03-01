Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :users do
      
      collection do
        get '/current-user', to: 'users#loggedInUser'
      end
    end

    resource :session, only: [:create, :destroy]
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  match '*path', via: [:options], to: lambda {|_| [204, { 'Content-Type' => 'text/plain' }]}
end
