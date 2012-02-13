require 'geokit'

include Geokit::Geocoders

Restaurant.all.first(50).each do |r|
	gc=MultiGeocoder.geocode(r.address)
	puts gc.ll # ll=latitude,longitude
end