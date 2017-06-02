class Subscription < ActiveRecord::Base
  has_many :schedules, foreign_key: :case_number, primary_key: :case_number
end
