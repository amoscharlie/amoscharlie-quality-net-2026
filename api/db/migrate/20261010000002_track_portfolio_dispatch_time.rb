class TrackPortfolioDispatchTime < ActiveRecord::Migration[7.0]
  def change
    add_column :portfolios, :generation_enqueued_at, :datetime
  end
end
