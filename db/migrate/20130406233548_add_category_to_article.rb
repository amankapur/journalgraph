class AddCategoryToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :category, :string
    add_column :articles, :comment, :string
  end
end
