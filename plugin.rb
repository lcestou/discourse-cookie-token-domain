# frozen_string_literal: true

# name: discourse-cookie-token-domain
# about: Add a cookie token to allow authentication for cross domain
# version: 0.2
# authors: mpgn, lcestou
# url: https://github.com/lcestou/discourse-cookie-token-domain

enabled_site_setting :cookie_token_domain_enabled

after_initialize do
  module ::DiscourseCookieTokenDomain
    PLUGIN_NAME = "discourse-cookie-token-domain"
  end

  require_relative "lib/discourse_cookie_token_domain/ex_current_user_provider"

  Discourse.current_user_provider = DiscourseCookieTokenDomain::ExCurrentUserProvider
end
