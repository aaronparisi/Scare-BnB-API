Rails.application.config.session_store :cookie_store, :key => '_session_id',
  :secure => Rails.env.production?

if Rails.env.production?
  Rails.application.config.action_dispatch.cookies_same_site_protection = :none
end