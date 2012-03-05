class WashingtonParser

	require 'mechanize'
	require 'nokogiri'
	require 'open-uri'
	require 'geokit'

	Mechanize.html_parser = Nokogiri::HTML
	@agent = Mechanize.new

	class << self
		include Geokit::Geocoders

		def geokit_geocode
			pass = 0
			total = 0
			Restaurant.where(:county => "Washington", :loc => {'$size' => 0 }).each do |r|
				total += 1
				res = MultiGeocoder.geocode(r.address)
				if res
					lat_long = res.ll.split(",")
					lat = lat_long.first.to_f
					long = lat_long.last.to_f
					loc = [long, lat]
					puts "#{r.name} -> #{r.address} -> #{r.loc}"
					r.save
					pass += 1
				end

			end
			
			puts "Total: #{total} | Succeeded: #{pass} (#{(total/pass)*100}%)"
		end

		def yahoo_geocode
			yk = "zJTs83vV34Eev5u7qgZIhICrZ0f20bNkRyvl9_XZmMMygNWXkDscK.z030x6UB4-"

			ungeocoded = Restaurant.where(:county => "Washington", :loc => {'$size' => 0 })
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

		def geocode_multnomah
			ungeocoded = Restaurant.where(:county => "Washington", :loc => {'$size' => 0 })
			total = ungeocoded.count
			ungeocoded.each_with_index do |r, idx|
				sleep 0.5
				coords = geocode_restaurant(r)
				next if coords.nil?
				lat = coords.first.to_f
				long = coords.last.to_f
				r.loc = [long, lat]
				puts "#{r.name} -> #{r.address} -> #{r.loc} (#{idx} of #{total})"
				r.save
			end
		end


		def geocode_restaurant(restaurant)

			return nil if restaurant['street_address'] == "&nbsp;"
			address = restaurant.address
			geocode_url = "http://maps.googleapis.com/maps/api/"
			geocode_url += "geocode/json?address=#{URI.escape(address)}"
			geocode_url += "&sensor=false&output=json"

			begin
				result_json = open(geocode_url).read
				result = JSON.parse(result_json)
			rescue Exception => e
				puts "Error getting geocoder result: #{e.inspect}"
			end

			if result['candidates'] && !result['candidates'].empty? 
				latitude = result['candidates'][0]['location']['y']
				longitude = result['candidates'][0]['location']['x']
				coordinates = [latitude, longitude]
			elsif result['status'] && result['status'] != 'ZERO_RESULTS'
				begin
					latitude = result['results'][0]['geometry']['location']['lat']
					longitude = result['results'][0]['geometry']['location']['lng']
					coordinates = [latitude, longitude]					
				rescue Exception => e
					puts "crapped out on #{result}"
				end
			end
			
			coordinates

		end # geocode_restaurants


		def fetch_restaurants
			search_page = @agent.get("http://washtech.co.washington.or.us/restaurantinspections/")
			index_page = search_page.forms.first.submit( search_page.forms.first.buttons.first )
			doc = Nokogiri::HTML(index_page.body)
			doc.search('//table[@border="1"]/tr').each_with_index do |row,idx|
				next if idx == 0
				td = row.search('./td')
				href = td[0].children.search("a").map{|link| link['href']}
				name = td[0].text.strip()
				address = td[1].text.strip()
				city = td[2].text.strip()
				zip = td[3].text.strip()
				puts "#{name}   #-> #{address} -> #{city} -> #{zip}"
			end

		end 

		
		def fetch_inspections 
			# change this for getting updated inspections
			#  currently just for getting missed ones
			no_inspections = Restaurant.where(:county => "Multnomah", :inspections => {'$size' => 0 })
			no_inspections.each do |r|
				fetch_inspections_for(r)
			end	
		end



		def fetch_inspections_for(restaurant=nil)
			top = @agent.get("http://washtech.co.washington.or.us/restaurantinspections/SelectInspect.asp?FacNbr=34008542")
			doc = Nokogiri::HTML(top.body)
			inspection_root = "http://washtech.co.washington.or.us/restaurantinspections"
			doc.search('//table[@border="1"]/tr').each_with_index do |row,idx|
				next if idx == 0

				td = row.search('./td')
				inspection_link = td[0].children.search("a").map{|link| link['href']}
				inspection_num = td[0].text.strip()
				inspection_type = td[1].text.strip()
				inspection_date = td[2].text.strip()
				final_score = td[3].text.strip()
		# puts href
			puts "#{inspection_num} #{inspection_type} #{inspection_date} #{final_score}"
			inspection = Inspection.new(
				:inspection_id => inspection_num,
				:inspection_type => inspection_type,
				:url => inspection_link,
				:inspection_date => Date.strptime(inspection_date, "%m/%d/%Y").to_s,
				:score => final_score.to_i > 0 ? final_score.to_i : nil
				)

			# now get the inspection page and violations
			end
		end # fetch_inspections_for

		def parse_index_row(row)
			return nil unless restaurant_id = row.search('a').count > 0 && row.search('a').attr('href').value.match(/id=(.*)/)

			Hash[
				*[:id, :name, :street_address, :city, :zip_code].zip( 
				[restaurant_id[1]] + row.search('td').map{|cell| cell.inner_html.gsub(%r{<.*?>}, "").strip} +[nil,nil]
				).flatten
			]
		end


		def click_button(page, button_name)
			page.forms.first.submit(
			page.forms.first.buttons.select{|b| b.name == button_name}.first
			)
		end
	end # class methods

end # class
