class ClackamasParser

  require 'nokogiri'
  require 'open-uri'
  require 'mechanize'

  class << self

    def titleize(str)
      str.split(/(\W)/).map(&:capitalize).join
    end

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

    def run_parser
      url = "http://www.clackamas.us/healthapp/ri.jsp"

      agent = Mechanize.new
      page = agent.get(url)
      form = page.forms.first
      # TODO: some sort of alert if the page DOM changes at all
      full_list = form.submit

      all_links = full_list.links.select{|l| l.href =~ /rim\.jsp\?q_ID=\d+/ }

      all_links.first(50).each do |l|

        # we're essentially parsing this:
        # http://www.clackamas.us/healthapp/rim.jsp?q_ID=0310774B&q_iID=1400723
        report = l.click

        # the first tr's first td is 4 lines with the contact info separated by br
        # the second td is a list of the inspections links
        info_block = report.parser.search("//table[@border='0']/tr[1]/td[1]")
        
        # Node
        name = info_block.first.children.first.text
        street = info_block.children[2].text

        # this is some bullshit here: sometimes
        # there's an empty line between the address 
        # and the rest of it
        if !info_block.children[4].text.empty?
          csz = info_block.children[4].text
        else
          csz = info_block.children[5].text
        end 
        csz.gsub!("\r\n", "")
        # spaces in the returned string are actually nbsp
        nbsp = Nokogiri::HTML("&nbsp;").text
        csz.gsub!(nbsp, " ")

        county = "Clackamas"
        state = "OR"

        r = nil
        if m = csz.match(/([A-Z ]*), (OR) (97\d{3})/)
          city = titleize(m[1]).strip
          zip = m[3]
          restaurant = Restaurant.create(:name => name, :street => street, 
          :city => city, :state => state,
          :zip => zip, :county => county)

        else  
          restaurant = Restaurant.create(:name => name, :state => state, :county => county)

        end

        # geocode that sum'bitch
        begin
          location = gc.locate(restaurant.address)
          restaurant.loc = location.coordinates          
        rescue Exception => e
          puts "something missed"
        end

        inspection_links = report.links.select{|l| l.href =~ /rim\.jsp\?q_ID=\d+/ }
        inspection_links.each do |i|
          idate = i.text
          inspection = i.click
          # puts "visiting #{i.href}"
          bottom_table = inspection.search("//table[@border='0']/tr[2]/td/table")
          # this is the comments and violations part
          bottom_table.each do |cell|
            kids = cell.children.search("td")
            insp_type = kids.shift.text
            score = kids.shift.text
            kids.shift # just the text Violations (the column header)
            kids.shift # also just a header

            violations = []
            kids.each_slice(2) do |k|
              vio = k.first.text
              pd = k.last.text
              
              violations << Violation.new(:violation_text => vio, :point_deduction => pd)
            end           

            inspection = Inspection.new(:inspection_date => idate, 
                                        :score => score.split(":").last.to_i,
                                        :url => i.href, 
                                        :violations => violations)

            restaurant.inspections << inspection
            restaurant.save
          end
        end

      end
    end # parser

  end # class methods

end # class
