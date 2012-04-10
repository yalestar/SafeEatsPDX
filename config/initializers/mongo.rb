if Rails.env == "development"
	MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
	MongoMapper.database = "safe_eats_pdx"

elsif Rails.env == "production"
	MongoMapper.connection = Mongo::Connection.new('flame.mongohq.com', 27052)
	db = MongoMapper.database = "safe_eats_pdx"
	auth = db.authenticate("yalestar", "eldongo1")

end
		
# mongodb://<user>:<password>@flame.mongohq.com:27052/app3879091
# MongoMapper.database = "pdx"

if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end