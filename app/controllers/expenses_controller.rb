class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[ show edit update destroy ]

  # GET /expenses or /expenses.json
  def index
    # 月選択
    if params[:month].present?
      @selected_month = Date.parse(params[:month] + "-01")
    else
      @selected_month = Date.current
    end

    # 対象月のデータ
    @expenses = Expense.where(
      date: @selected_month.beginning_of_month..
            @selected_month.end_of_month
    ).order(date: :desc)

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
  end

  # GET /expenses/1 or /expenses/1.json
  def show
  end

  # GET /expenses/new
  def new
    @expense = Expense.new
  end

  # GET /expenses/1/edit
  def edit
  end

  # POST /expenses or /expenses.json
  def create
    @expense = Expense.new(expense_params)

    respond_to do |format|
      if @expense.save
        format.html {
          redirect_to @expense,
          notice: "支出を登録しました。"
        }
        format.json { render :show, status: :created, location: @expense }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenses/1 or /expenses/1.json
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html {
          redirect_to @expense,
          notice: "支出を更新しました。",
          status: :see_other
        }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1 or /expenses/1.json
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

  # Use callbacks to share common setup or constraints between actions.
  def set_expense
    @expense = Expense.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def expense_params
    params.require(:expense).permit(
      :title,
      :amount,
      :date,
      :category
    )
  end
end
