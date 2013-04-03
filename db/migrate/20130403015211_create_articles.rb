class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :arxiv_id
      t.string :arxiv_url
      t.text :summary
      t.datetime :published_date
      t.datetime :update_date
      t.string :title

      t.timestamps
    end
  end
end
