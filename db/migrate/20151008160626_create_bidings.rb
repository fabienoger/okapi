class CreateBidings < ActiveRecord::Migration
  def change
    create_table :bidings do |t|
      t.integer :keyword_id
      t.integer :binded_keyword_id

      t.timestamps null: false
    end
  end
end