require 'mechanize'
require 'nokogiri'
require 'open-uri'

Mechanize.html_parser = Nokogiri::HTML
@agent = Mechanize.new

def fetch_restaurants
	search_page = @agent.get("http://www3.multco.us/MCHealthInspect/ListSearch.aspx")

	puts "===> "
	index_page = search_page.forms.first.submit( search_page.forms.first.buttons.first )

	loop do
		Nokogiri::HTML( index_page.body ).search('#ResultsDataGrid tr').each do |row|
			if restaurant_data = parse_index_row(row)

				
				puts "Saved: #{restaurant_data[:name]}"
			end
		end

		break unless index_page.forms.first.buttons.select{|b| b.name == 'Next'}.first

		successful = false
		until successful do
			begin
				index_page = click_button(index_page, 'Next')
			rescue Timeout::Error => e
				puts "[-!-] Timeout fetching page, retrying..."
			rescue Net::HTTPInternalServerError => e
				puts "[-!-] 500 Internal Server Error fetching page, retrying..."
			else
				successful = true
			end
		end
	end

	puts "==========================="
end
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

def fetch_inspections_for(restaurant)
	url = "http://www3.multco.us/MCHealthInspect/ListSearch.aspx?id=#{restaurant['id']}"
	puts "Fetching inspections for #{restaurant['name']} at #{url}"
	inspection_page = @agent.get(url)

	inspection_count = inspection_page.search('span#Label4 b').text.to_i

	if inspection_count > 0
		loop do
			inspection_data = parse_inspection_page(inspection_page)
			inspection_data[:restaurant_id] = restaurant['id']
			notes = inspection_data.delete(:inspection_notes)

			ScraperWiki.save_sqlite(unique_keys=[:id],
			data=inspection_data,
			table_name='inspections')
			puts "Saved: #{inspection_data.inspect}"

			ScraperWiki.save_sqlite(unique_keys=[:rule, :rule_violations, :violation_comments, :corrective_text, :corrective_comments],
			data=notes,
			table_name='inspection_notes')
			puts "Saved: #{notes.inspect}"

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
rescue Net::HTTP::Persistent::Error
	puts "[-!-] Connection Reset fetching page, skipping..."
rescue Net::HTTPInternalServerError
	puts "[-!-] 500 Internal Server Error fetching page, skipping..."
end

private


def parse_inspection_page(inspection_page)
	doc = Nokogiri::HTML(inspection_page.body)
	rows = doc.search('#DetailsView table tr').map{|row| 
		row.search('td, th').map{|cell| 
			cell.inner_text.gsub(/\u00a0/,'').strip 
		}
	}
	summary = Hash[*rows[0].zip(rows[1]).flatten]

	notes = []
	rows.each_with_index do |row, i|
		if row.sort == ["", "Law/Rule", "Rule Violations", "Violation Comments"].sort
			notes << {
				:rule => rows[i+1][0],
				:rule_violations => rows[i+1][1],
				:violation_comments => rows[i+1][2],
				:corrective_text => rows[i+3][1],
				:corrective_comments => rows[i+3][1]
			}
		end
	end

	return {
		:id => summary["Inspection#"],
		:type => summary["Type"],
		:date => Date.strptime(summary["Date"], "%m/%d/%Y").to_s,
		:score => summary["Final Score"].to_i > 0 ? summary["Final Score"].to_i : nil,
		:inspection_notes => notes
	}
end
end
