class CreateLinkedMarks < ActiveRecord::Migration
  def change
    create_table :linked_marks do |t|
      t.references :user, index: true, foreign_key: true
      t.references :linked, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
