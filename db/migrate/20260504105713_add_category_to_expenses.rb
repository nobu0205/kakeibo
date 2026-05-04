class AddCategoryToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :category, :string
  end
end
