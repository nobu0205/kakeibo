class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.string :title
      t.integer :amount
      t.date :date

      t.timestamps
    end
  end
end
