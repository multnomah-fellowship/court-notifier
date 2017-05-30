class Schedule < ActiveRecord::Base
  scope :on_or_after, ->(date) { where('DATE(datetime) >= ?', date) }
end
