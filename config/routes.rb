Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  devise_scope :user do
    post "users/guest_sign_in",
      to: "users/sessions#guest"
  end

  resources :expenses
  root "expenses#index"

  get "up" => "rails/health#show",
      as: :rails_health_check
end
