require_relative './environment.rb'

require 'haml'
require 'sinatra'
require 'sinatra/reloader' if development?

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

after do
  ActiveRecord::Base.clear_active_connections!
end

get '/' do
  subscriptions = Subscription.all
  haml :index, locals: { subscriptions: subscriptions }
end

post '/update' do
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  today = tz.utc_to_local(Time.now.utc).to_date

  ScheduleUpdater.new(today).update

  redirect '/'
end

post '/subscriptions' do
  Subscription.create(
    phone_number: params[:phone_number],
    case_number: params[:case_number]
  )

  redirect '/'
end

get '/subscriptions/:id/delete' do
  Subscription.find(params[:id]).destroy

  redirect '/'
end
