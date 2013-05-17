class ChangeDataTypeForFieldname < ActiveRecord::Migration
  def up
    change_column :articles, :comment, :text
    change_column :articles, :keywords, :text
    change_column :articles, :title, :text
  end

  def down
    change_column :articles, :comment, :string
    change_column :articles, :keywords, :string
    change_column :articles, :title, :string

  end
end
