class TransactionsController < ApplicationController
  CURRENCIES = %w[btc eth].freeze

  before_action :check_and_set_currency

  def create
    response = Processing::new_transaction.call(@currency,
                                                params[:to],
                                                params[:amount])

    if response.blank? || response[:errors].size.positive?
      render json: { errors: response[:errors] }, status: :unprocessable_entity
      return
    end

    transaction = Transaction.create currency: @currency,
                                     transaction_id: response[:transaction_id],
                                     amount: -1 * params[:amount].to_i, # We are sending
                                     target: params[:to],
                                     user: User.first
    if transaction.persisted?
      render json: transaction, status: :created
    else
      render json: { errors: ['Unable to create transaction', transaction.errors.full_messages] },
             status: :unprocessable_entity
    end
  end

  def index
  end

  private

    def check_and_set_currency
      if params[:currency].blank? ||
         !CURRENCIES.include?(params[:currency].downcase)
        render json: { errors: ['Currency is empty or not supported'] },
               status: :bad_request
      end
      @currency = params[:currency]
    end

    def transaction_params
      params.require(:transaction).permit(:amount, :to)
    end

end
