FactoryGirl.define do
  factory :subscription do
    sequence(:case_number) { |i| "17CR%0.4d" % i }
    phone_number '+14155551234'
  end
end
