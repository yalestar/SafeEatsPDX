class Geocoder
	require 'geokit'
	require 'json'
	require 'open-uri'
	
	include Geokit::Geocoders

	# # geocode that sum'bitch
	# begin
	#   location = gc.locate(restaurant.address)
	#   restaurant.loc = location.coordinates          
	# rescue Exception => e
	#   puts "something missed"
	# end

	class << self
		def google_geocode

		  Restaurant.where(:county => "Clackamas", :loc => {'$size' => 0 }).each do |r|

		    coords = geocode_restaurant(r)
		    next if coords.nil?
		    lat = coords.first.to_f
		    long = coords.last.to_f
		    r.loc = [long, lat]
		    puts "#{r.name} -> #{r.address} -> #{r.loc}"
		    r.save
		  end
		end

		# TODO: parameterize by county
		def yahoo_geocode
		  yk = "zJTs83vV34Eev5u7qgZIhICrZ0f20bNkRyvl9_XZmMMygNWXkDscK.z030x6UB4-"

		  # ungeocoded = Restaurant.where(:county => "Clackamas", :loc => {'$size' => 0 })
		  ungeocoded = Restaurant.where(:county => "Clackamas")
		  total = ungeocoded.count
		  ungeocoded.each_with_index do |restaurant, idx|
		    next if restaurant.street.nil?  
		    sleep 0.5
		    geocode_url= "http://where.yahooapis.com/"
		    geocode_url += "geocode?location=#{URI.escape(restaurant.address)}"
		    geocode_url += "&flags=J&appid=#{yk}"

		    begin
		      result_json = open(geocode_url).read
		      result = JSON.parse(result_json)
		      r = result['ResultSet']['Results'].first

		      lat = r['latitude'].to_f
		      lng = r['longitude'].to_f
		      coords = [lng, lat]
		      next if coords.nil?
		      restaurant.loc = [lng, lat]
		      puts "#{restaurant.name} -> #{restaurant.address} -> #{restaurant.loc} (#{idx} of #{total})"
		      restaurant.save
		    rescue Exception => e
		      puts "Error getting geocoder result: #{e.inspect}"
		    end

		  end

		end

	end

end