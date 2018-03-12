class User < ApplicationRecord
  has_secure_password

  has_many :wallets
  has_many :transactions
end
