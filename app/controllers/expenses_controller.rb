require "csv"

class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ]

  # GET /expenses
  def index
    # 月選択
    if params[:month].present?
      @selected_month = Date.parse(params[:month] + "-01")
    else
      @selected_month = Date.current
    end

    # ログインユーザーの支出だけ取得
    @expenses = current_user.expenses.where(
      date: @selected_month.beginning_of_month..
            @selected_month.end_of_month
    )

    # 並び替え
    case params[:sort]
    when "latest"
      @expenses = @expenses.order(date: :desc)

    when "old"
      @expenses = @expenses.order(date: :asc)

    when "amount_desc"
      @expenses = @expenses.order(amount: :desc)

    when "amount_asc"
      @expenses = @expenses.order(amount: :asc)

    else
      @expenses = @expenses.order(date: :desc)
    end

    # キーワード検索
    if params[:keyword].present?
      @expenses = @expenses.where(
        "title LIKE ?",
        "%#{params[:keyword]}%"
      )
    end

    # カテゴリ絞り込み
    if params[:category].present?
      @expenses = @expenses.where(category: params[:category])
    end

    # 合計
    @total_amount = @expenses.sum(:amount)

    # カテゴリ別
    @category_totals = @expenses.group(:category).sum(:amount)

    # 月別
    @monthly_totals = @expenses.group_by_month(:date).sum(:amount)

    # 今月データ
    @this_month_expenses = @expenses

    @month_total = @this_month_expenses.sum(:amount)

    @month_count = @this_month_expenses.count

    @max_expense = @this_month_expenses.maximum(:amount) || 0

    @analysis_messages = []

budget = current_user.budgets.find_by(
  month: @selected_month.beginning_of_month
)

if budget && @month_total > budget.amount
  @analysis_messages << "⚠️ 予算を超過しています"
elsif budget && @month_total > budget.amount * 0.8
  @analysis_messages << "⚠️ 予算の80%以上を使用しています"
end

if @month_total > 0
  food_ratio = (
    @category_totals["食費"].to_i.to_f / @month_total
  )

  if food_ratio > 0.4
    @analysis_messages << "🍽 食費の割合が高めです"
  end
end

if @max_expense > 5000
  @analysis_messages << "💸 高額支出があります"
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

  # GET /expenses/1
  def show
  end

  # GET /expenses/new
  def new
    @expense = current_user.expenses.new
  end

  # GET /expenses/1/edit
  def edit
  end

  # POST /expenses
  def create
    @expense = current_user.expenses.new(expense_params)

    respond_to do |format|
      if @expense.save
        format.html {
          redirect_to @expense,
          notice: "支出を登録しました。"
        }

        format.json {
          render :show,
          status: :created,
          location: @expense
        }
      else
        format.html {
          render :new,
          status: :unprocessable_entity
        }

        format.json {
          render json: @expense.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /expenses/1
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html {
          redirect_to @expense,
          notice: "支出を更新しました。",
          status: :see_other
        }

        format.json {
          render :show,
          status: :ok,
          location: @expense
        }
      else
        format.html {
          render :edit,
          status: :unprocessable_entity
        }

        format.json {
          render json: @expense.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /expenses/1
  def destroy
    @expense.destroy!

    respond_to do |format|
      format.html {
        redirect_to expenses_path,
        notice: "支出を削除しました。",
        status: :see_other
      }

      format.json { head :no_content }
    end
  end

  private

  # 他人のデータを触れないようにする
  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  # Strong Parameters
  def expense_params
    params.require(:expense).permit(
      :title,
      :amount,
      :date,
      :category
    )
  end
end
