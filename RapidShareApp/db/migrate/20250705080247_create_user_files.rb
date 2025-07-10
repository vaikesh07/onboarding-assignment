class CreateUserFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :user_files do |t|
      t.string :name
      t.string :file
      t.references :user, null: false, foreign_key: true
      
      # Inside the create_table block:
      t.boolean :shareable, default: false
      t.string :share_token
      t.timestamps
    end
    add_index :user_files, :share_token, unique: true
  end
end
