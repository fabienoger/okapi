class CreateLinkeds < ActiveRecord::Migration
  def change
    create_table :linkeds do |t|
      t.references :keyword, index: true, foreign_key: true
      t.integer :linked_keyword_id

      t.timestamps null: false
    end
  end
end
