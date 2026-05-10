class Expense < ApplicationRecord
  validates :title, presence: true
  validates :amount, presence: true

  def start_time
    date
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << [
        "タイトル",
        "金額",
        "カテゴリ",
        "日付"
      ]

      all.each do |expense|
        csv << [
          expense.title,
          expense.amount,
          expense.category,
          expense.date
        ]
      end
    end
  end
end
