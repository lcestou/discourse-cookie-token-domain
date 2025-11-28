# frozen_string_literal: true

module DiscourseCookieTokenDomain
  class ExCurrentUserProvider < Auth::DefaultCurrentUserProvider
    TOKEN_COOKIE = "logged_in"

    def log_on_user(user, session, cookies, opts = {})
      super

      return unless SiteSetting.cookie_token_domain_enabled

      payload = {
        username: user.username,
        user_id: user.id,
        avatar: user.avatar_template,
        group: user.title
      }

      payload_sha = Digest::SHA256.hexdigest(payload.to_json)
      hmac = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        SiteSetting.cookie_token_domain_key,
        payload_sha
      )

      payload[:hmac] = hmac
      token = Base64.strict_encode64(payload.to_json)

      cookies.permanent[TOKEN_COOKIE] = {
        value: token,
        httponly: false,
        secure: Rails.env.production?,
        same_site: :none,
        domain: :all
      }
    end

    def log_off_user(session, cookies)
      super

      cookies.delete(TOKEN_COOKIE, domain: :all)
    end
  end
end
