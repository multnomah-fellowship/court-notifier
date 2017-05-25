require_relative './environment.rb'

include ActiveRecord::Tasks
DatabaseTasks.env = ENV['APP_ENV']
DatabaseTasks.database_configuration = Hash.new(url: ENV['DATABASE_URL'])
DatabaseTasks.db_dir = 'db'
DatabaseTasks.migrations_paths = 'db/migrate'

task :environment do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end

namespace :update do
  desc 'Update seven days of court cases'
  task schedules: :environment do
    ScheduleUpdater.new(Date.today).update
  end
end

namespace :db do
  desc 'Migrate the database'
  task migrate: :environment do
    DatabaseTasks.migrate
  end

  desc 'Drop and recreate the database'
  task recreate: :environment do
    DatabaseTasks.drop_all
    DatabaseTasks.create_all
    DatabaseTasks.migrate
  end
end
