FactoryGirl.define do
  factory :schedule do
    sequence(:case_number) { |i| "17CR%0.4d" % i }
    schedule_type 'Offense Felony'
    style "State of Oregon\nvs.\nJohn Doe"
    judicial_officer 'Judge Foo Bar'
    datetime { Time.strptime('2017-05-30 11:30', '%Y-%m-%d %H:%M') }
    hearing_type 'Arraignment'
  end
end
