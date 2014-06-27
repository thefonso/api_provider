ApiProvider::Application.routes.draw do
  
  namespace :api do
   resources :users, :defaults => { :format => 'json' }
  end
  
  # take a peek at Ryan Baytes Railscast 350 to help with illumination
end
