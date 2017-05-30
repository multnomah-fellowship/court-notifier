class CreateChangeLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :change_logs do |t|
      t.string :case_number
      t.string :change_type
      t.json :change_contents
      t.timestamps
    end
  end
end
