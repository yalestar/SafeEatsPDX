MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
MongoMapper.database = "safe_eats_pdx"

if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end