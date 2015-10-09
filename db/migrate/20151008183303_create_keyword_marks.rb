class CreateKeywordMarks < ActiveRecord::Migration
  def change
    create_table :keyword_marks do |t|
      t.integer :note
      t.references :user, index: true, foreign_key: true
      t.references :keyword, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
