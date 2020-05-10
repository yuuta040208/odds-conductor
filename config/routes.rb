Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :odds, to: 'odds#show'
    end
  end
end
