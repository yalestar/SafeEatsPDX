require 'geokit'
require 'json'
require 'open-uri'

include Geokit::Geocoders

c = 0
crappers = []
gc = Graticule.service(:google).new(GOOGLE_API_KEY)
Restaurant.all.first(50).each do |r|
    c+=1
    address = r.address
    location = gc.locate(address)
    puts "#{address} -> #{location.coordinates}"
end
