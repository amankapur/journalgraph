class AddPagerankToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :pagerank, :float
  end
end
