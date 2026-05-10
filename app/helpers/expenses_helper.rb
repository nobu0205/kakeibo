module ExpensesHelper
  def category_color(category)
    case category
    when "食費"
      "bg-green-500"
    when "交通費"
      "bg-blue-500"
    when "娯楽"
      "bg-purple-500"
    else
      "bg-gray-500"
    end
  end
end
