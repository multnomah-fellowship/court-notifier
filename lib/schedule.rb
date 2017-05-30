class Schedule < ActiveRecord::Base
  scope :on_or_after, ->(date) { where('DATE(datetime) >= ?', date) }

  has_many :subscriptions, primary_key: :case_number, foreign_key: :case_number
end
