require 'active_record'

class CreateCourtCases < ActiveRecord::Migration[5.0]
  def change
    create_table :schedules do |t|
      t.string :case_number
      t.string :schedule_type
      t.string :style
      t.string :judicial_officer
      t.string :physical_location
      t.datetime :datetime
      t.string :hearing_type

      t.index :case_number
    end
  end
end
