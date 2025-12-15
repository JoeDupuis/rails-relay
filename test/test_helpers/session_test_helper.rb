module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      if defined?(page)
        page.driver.set_cookie(:session_id, cookie_jar[:session_id])
      else
        cookies[:session_id] = cookie_jar[:session_id]
      end
    end
  end

  def sign_out
    if defined?(page)
        Current.session&.destroy!
        page.driver.remove_cookie(:session_id)

    else
        Current.session&.destroy!
        cookies.delete(:session_id)
    end
  end
end
