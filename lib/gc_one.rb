require 'rubygems'
require 'geokit'
require 'json'
require 'open-uri'

include Geokit::Geocoders


	address = "4250 MERCANTILE DRIVE, Lake Oswego, OR 97035"
	# geocode_url = 'http://tasks.arcgisonline.com/ArcGIS/rest/services/Locators/TA_Streets_US_10/GeocodeServer/findAddressCandidates?Single+Line+Input='+URI.escape(address)+'&outFields=&outSR=&f=json'
	geocode_url = 'http://maps.googleapis.com/maps/api/geocode/json?address='+URI.escape(address)+'&sensor=false&output=json'
	result_json = open(geocode_url).read
	result = JSON.parse(result_json)

    if result['candidates'] && !result['candidates'].empty? 
      latitude = result['candidates'][0]['location']['y']
      longitude = result['candidates'][0]['location']['x']
    elsif result['status'] && result['status'] != 'ZERO_RESULTS'
      begin
	      latitude = result['results'][0]['geometry']['location']['lat']
	      longitude = result['results'][0]['geometry']['location']['lng']      	
      rescue Exception => e
      	puts "crapped out on: #{e}" 
      end
    end

   puts "#{address} -> #{latitude} #{longitude}"
