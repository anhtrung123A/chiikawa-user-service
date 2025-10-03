class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :city, null: false
      t.text :location_detail, null: false
      t.string :phone_number, null: false
      t.string :recipient_name, null: false

      t.timestamps
    end
  end
end
