class WalletController < ApplicationController
  def create
  end

  def index
    user = User.first

    balance = {}
    user.wallets.each do |wallet|
      balance[wallet.currency] = {} unless balance.key?(wallet.currency)
      balance[wallet.currency][wallet.wallet] = [] unless balance[wallet.currency].key?(wallet.wallet)

      Transaction.for_wallet(wallet).each do |trans|
        balance[wallet.currency][wallet.wallet] << trans
      end
    end

    render json: balance, status: :ok
  end
end
