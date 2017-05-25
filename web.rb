require_relative './environment.rb'

require 'sinatra'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

after do
  ActiveRecord::Base.clear_active_connections!
end

get '/' do
  '<form method="POST" action="/update"><input type="submit" value="Update Now!" /></form>'
end

post '/update' do
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  today = tz.utc_to_local(Time.now.utc).to_date

  ScheduleUpdater.new(today).update

  redirect '/'
end
