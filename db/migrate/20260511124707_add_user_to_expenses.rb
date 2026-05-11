class AddUserToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_reference :expenses, :user, foreign_key: true
  end
end
