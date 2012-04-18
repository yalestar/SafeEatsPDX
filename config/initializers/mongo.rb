require 'uri'
require 'mongo'

if Rails.env == "development"
	MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
	MongoMapper.database = "safe_eats_pdx"

elsif Rails.env == "production"
	# uri = URI.parse(ENV['MONGOHQ_URL'])
	# conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
	# db = conn.db(uri.path.gsub(/^\//, ''))
	# MongoMapper.database = db
	# MongoMapper.connection = Mongo::Connection.new('flame.mongohq.com', 27052)
	# mongo ds031857.mongolab.com:31857/heroku_app3879091
	# was: MONGOLAB_URI        => mongodb://heroku_app3879091:5381mrrk440iq18dbd9bqjl6hq@ds031857.mongolab.com:31857/heroku_app3879091
	MongoMapper.config = { 
  	Rails.env => { 'uri' => ENV['MONGOLAB_URI'] }
# mongodb://<user>:<password>@ds031857.mongolab.com:31857/heroku_app3879091
	MongoMapper.connect(Rails.env)

end
		
if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end