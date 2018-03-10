Rails.application.routes.draw do
  post 'sessions/' => 'sessions#create'
  delete 'sessions/' => 'sessions#destroy'

  post 'users' => 'users#create'
  match 'users' => 'users#update', via: [:put, :patch]

  post 'wallet/:currency' => 'wallet#create'
  get 'wallet' => 'wallet#index'

  scope ':currency' do
    resources :transactions, only: [:create, :index]
  end
end
