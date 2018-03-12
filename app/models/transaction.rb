class Transaction < ApplicationRecord
  belongs_to :user, optional: true

  scope(:for_wallet, lambda do |wallet|
    where(source: wallet.wallet)
      .or(Transaction.where(target: wallet.wallet))
      .where(currency: wallet.currency)
  end)
end
