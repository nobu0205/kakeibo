class Users::SessionsController < Devise::SessionsController
  def guest
    user = User.find_or_create_by!(email: "guest@example.com") do |user|
      user.password = SecureRandom.urlsafe_base64
    end

    sign_in user
    redirect_to expenses_path, notice: "ゲストログインしました。"
  end
end
