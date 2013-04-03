class CreateCreations < ActiveRecord::Migration
  def change
    create_table :creations do |t|
      t.integer :article_id
      t.integer :author_id

      t.timestamps
    end
  end
end
