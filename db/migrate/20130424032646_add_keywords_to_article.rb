class AddKeywordsToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :keywords, :string
  end
end
