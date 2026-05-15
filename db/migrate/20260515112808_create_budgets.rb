class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.integer :amount
      t.date :month
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
