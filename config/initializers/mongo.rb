require 'uri'
require 'mongo'

MongoMapper.config = {
  Rails.env => { 'uri' => ENV['MONGOLAB_URI'] }
}
MongoMapper.connect(Rails.env)



if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect if forked
  end
end
