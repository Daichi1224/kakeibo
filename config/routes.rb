Rails.application.routes.draw do
  # LINE Webhook
  post "webhook", to: "webhook#create"

  # Dashboard
  root "dashboard#index"
  get "expenses", to: "dashboard#expenses"
  get "reports", to: "dashboard#reports"
  get "reports/:id", to: "dashboard#report_detail", as: :report_detail

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
