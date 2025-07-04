class CreateUserFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :user_files do |t|
      t.string :name
      t.string :content_type
      t.integer :size
      t.binary :data
      t.references :user, null: false, foreign_key: true
      
      # Add the sharing fields here
      t.boolean :shareable, default: false
      t.string :share_token

      t.timestamps
    end
    # Add the index for the token outside the block
    add_index :user_files, :share_token, unique: true
  end
end
