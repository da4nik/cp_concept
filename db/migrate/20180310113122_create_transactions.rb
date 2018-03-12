class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.string :transaction_id
      t.string :currency
      t.string :source
      t.string :target
      t.integer :amount
      t.string :status, default: 'unconfirmed'
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
