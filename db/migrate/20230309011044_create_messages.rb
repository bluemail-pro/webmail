class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :from
      t.string :to
      t.string :subject
      t.string :body
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
