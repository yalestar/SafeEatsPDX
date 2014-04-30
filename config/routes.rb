SafeEatsPDX::Application.routes.draw do
  get "restaurant/index"
  get "restaurant/show"
  get "/find_nearest" => "restaurants#find_nearest"
  get "/testpage" => "restaurants#testpage"
  root :to => "restaurants#index"

end
