class AddJournalRefToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :journal_ref, :string
    add_column :articles, :doi, :string
  end
end
