class Schedule < ActiveRecord::Base
  scope :on_date, ->(date) { where('DATE(datetime) = ?', date) }
end
