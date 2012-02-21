class MultnomahParser

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
			Restaurant.where(:county => "Multnomah", :loc => {'$size' => 0 }).each do |r|
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


		def geocode_multnomah

			Restaurant.where(:county => "Multnomah", :loc => {'$size' => 0 }).each do |r|

				coords = geocode_restaurant(r)
				next if coords.nil?
				lat = coords.first.to_f
				long = coords.last.to_f
				r.loc = [long, lat]
				puts "#{r.name} -> #{r.address} -> #{r.loc}"
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
			search_page = @agent.get("http://www3.multco.us/MCHealthInspect/ListSearch.aspx")
			index_page = search_page.forms.first.submit( search_page.forms.first.buttons.first )

			loop do
				# this step loads all the Multnomah restaurants into the DB.
				# the inspection parsing comes subsequently
				Nokogiri::HTML( index_page.body ).search('#ResultsDataGrid tr').each do |row|
					if restaurant_data = parse_index_row(row)

						restaurant = Restaurant.create(:name => restaurant_data[:name], 
						:street => restaurant_data[:street_address], 
						:city => restaurant_data[:city], :state => restaurant_data[:state],
						:zip => restaurant_data[:zip_code], :county => "Multnomah")
						puts "Saved: #{restaurant_data[:name]}"
					end
				end

				break unless index_page.forms.first.buttons.select{|b| b.name == 'Next'}.first

				successful = false
				until successful do
					begin
						index_page = click_button(index_page, 'Next')
					rescue Timeout::Error => e
						puts "[-!-] Timeout fetching page; retrying..."
					rescue Net::HTTPInternalServerError => e
						puts "[-!-] 500 Internal Server Error fetching page; retrying..."
					else
						successful = true
					end
				end
			end
		end # fetch_restaurants


		def parse_inspection_page(inspection_page)
			doc = Nokogiri::HTML(inspection_page.body)
			rows = doc.search('#DetailsView table tr').map{|row| 
				row.search('td, th').map{ |cell| 
					cell.inner_text.gsub(/\u00a0/,'').strip 
				}
			}
			summary = Hash[*rows[0].zip(rows[1]).flatten]

			notes = []
			
			violations = []
			rows.each_with_index do |row, i|
				if row.sort == ["", "Law/Rule", "Rule Violations", "Violation Comments"].sort
					# no point deductions for multnomah?
					violations << Violation.new(
						:rule => rows[i+1][0], 
						:violation_text => rows[i+1][1],
						:violation_comments => rows[i+1][2], 
						:corrective_text => rows[i+3][1],
						:corrective_comments => rows[i+3][1] )
				end
			end

			inspection = Inspection.new(
				:inspection_id => summary["Inspection#"],
				:inspection_type => summary["Type"],
				:url => inspection_page.url,
				:inspection_date => Date.strptime(summary["Date"], "%m/%d/%Y").to_s,
				:score => summary["Final Score"].to_i > 0 ? summary["Final Score"].to_i : nil,
				:notes => notes
			)
			inspection.violations << violations

			inspection
		end # parse_inspection_page

		def fetch_inspections_for(restaurant)
			url = "http://www3.multco.us/MCHealthInspect/ListSearch.aspx?id=#{restaurant['id']}"
			puts "Fetching inspections for #{restaurant['name']} at #{url}"
			inspection_page = @agent.get(url)

			inspection_count = inspection_page.search('span#Label4 b').text.to_i

			if inspection_count > 0
				loop do
					inspection = parse_inspection_page(inspection_page)
					restaurant.inspections << inspection
					restaurant.save
					puts "Saved: #{restaurant.inspect}"

					break unless inspection_page.forms.first.buttons.select{|b| b.name == 'NextInspection'}.first

					successful = false
					until successful do
						begin
							inspection_page = click_button(inspection_page, 'NextInspection')
						rescue Timeout::Error => e
							puts "[-!-] Timeout fetching page, retrying..."
						else
							successful = true
						end
					end
				end
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
