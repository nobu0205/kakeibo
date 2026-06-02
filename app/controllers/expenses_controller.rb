require "csv"

class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[show edit update destroy]

  def index
    # 月選択
    @selected_month =
      if params[:month].present?
        Date.parse("#{params[:month]}-01")
      else
        Date.current
      end

    month_range = @selected_month.beginning_of_month..@selected_month.end_of_month

    # ベースクエリ（この月のユーザー支出）
    base_scope = current_user.expenses.where(date: month_range)

    # 一覧用（ここで初めて order）
    @expenses =
      case params[:sort]
      when "latest"
        base_scope.order(date: :desc)
      when "old"
        base_scope.order(date: :asc)
      when "amount_desc"
        base_scope.order(amount: :desc)
      when "amount_asc"
        base_scope.order(amount: :asc)
      else
        base_scope.order(date: :desc)
      end

    # キーワード検索
    if params[:keyword].present?
      @expenses = @expenses.where("title LIKE ?", "%#{params[:keyword]}%")
    end

    # カテゴリ絞り込み
    if params[:category].present?
      @expenses = @expenses.where(category: params[:category])
    end

    # 合計
    @total_amount = @expenses.sum(:amount)

    # ⭐重要：group + order 衝突回避
    @category_totals =
      @expenses.reorder(nil).group(:category).sum(:amount)

    # 月別（安全に別クエリ）
    @monthly_totals =
      current_user.expenses
        .group("DATE_TRUNC('month', date)")
        .sum(:amount)

    # 今月データ
    @this_month_expenses = @expenses
    @month_total = @this_month_expenses.sum(:amount)
    @month_count = @this_month_expenses.count
    @max_expense = @this_month_expenses.maximum(:amount) || 0

    # 前月比較
    previous_month = @selected_month.prev_month
    previous_range = previous_month.beginning_of_month..previous_month.end_of_month

    @previous_total =
      current_user.expenses.where(date: previous_range).sum(:amount)

    @comparison_rate =
      if @previous_total > 0
        (((@month_total - @previous_total).to_f / @previous_total) * 100).round
      else
        0
      end

    # 分析
    @analysis_messages = []

    budget =
      current_user.budgets.find_by(month: @selected_month.beginning_of_month)

    if budget && @month_total > budget.amount
      @analysis_messages << "⚠️ 予算を超過しています"
    elsif budget && @month_total > budget.amount * 0.8
      @analysis_messages << "⚠️ 予算の80%以上を使用しています"
    end

    if @month_total > 0
      food_ratio = @category_totals["食費"].to_f / @month_total
      @analysis_messages << "🍽 食費の割合が高めです" if food_ratio > 0.4
    end

    @analysis_messages << "💸 高額支出があります" if @max_expense > 5000

    if @previous_total > 0
      if @comparison_rate > 20
        @analysis_messages << "📈 前月より#{@comparison_rate}%支出が増加しています"
      elsif @comparison_rate < -10
        @analysis_messages << "📉 前月より#{@comparison_rate.abs}%節約できています"
      end
    end

    if @analysis_messages.empty?
      @analysis_messages << "✅ バランスよく支出管理できています"
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @expenses.to_csv,
                  filename: "expenses-#{Date.today}.csv"
      end
    end
  end

  def show; end

  def new
    @expense = current_user.expenses.new
  end

  def edit; end

  def create
    @expense = current_user.expenses.new(expense_params)

    if @expense.save
      redirect_to @expense, notice: "支出を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      redirect_to @expense, notice: "支出を更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy!
    redirect_to expenses_path, notice: "支出を削除しました。", status: :see_other
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :date, :category)
  end
end
