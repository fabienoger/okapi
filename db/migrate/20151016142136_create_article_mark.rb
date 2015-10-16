class CreateArticleMark < ActiveRecord::Migration
  def change
    create_table :article_marks do |t|
      t.integer :note
      t.integer :article_id
      t.references :user, index: true, foreign_key: true
    end
  end
end
