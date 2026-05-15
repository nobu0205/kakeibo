class Budget < ApplicationRecord
  belongs_to :user

  validates :amount,
            presence: true,
            numericality: { greater_than: 0 }

  validates :month, presence: true

  validates :month,
            uniqueness: {
              scope: :user_id
            }
end
