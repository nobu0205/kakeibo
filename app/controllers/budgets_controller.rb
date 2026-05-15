class BudgetsController < ApplicationController
  before_action :authenticate_user!

  def new
    @budget = current_user.budgets.new
  end

  def create
    selected_month = Date.parse(
      "#{budget_params[:month]}-01"
    )

    @budget = current_user.budgets.find_or_initialize_by(
      month: selected_month
    )

    @budget.amount = budget_params[:amount]

    if @budget.save
      redirect_to expenses_path,
                  notice: "予算を設定しました。"
    else
      render :new,
             status: :unprocessable_entity
    end
  end

  private

  def budget_params
    params.require(:budget).permit(:amount, :month)
  end
end
