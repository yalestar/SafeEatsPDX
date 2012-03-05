require 'mechanize'
require 'nokogiri'
require 'open-uri'

Mechanize.html_parser = Nokogiri::HTML
@agent = Mechanize.new


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

def fetch_inspections(restaurant=nil)
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
		parse_inspection_page(inspection_link)
	end


end

def parse_inspection_page(url)
	doc = Nokogiri::HTML(@agent.get(url))
	
end

fetch_inspections()
# fetch_restaurants()