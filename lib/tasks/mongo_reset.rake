namespace :db_maintenance do
	desc "Delete everything in the current mongoDB"
	task :mongo_reset => :environment do
		Inspection.destroy_all
		Restaurant.destroy_all
	end
end