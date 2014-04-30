require 'nokogiri'
require 'open-uri'
require 'mechanize'

def titleize(str)
  str.split(/(\W)/).map(&:capitalize).join
end

def run_parser(url)
  agent = Mechanize.new
  report = agent.get(url)

  # the first tr's first td is 4 lines with the contact info separated by br
  # the second td is a list of the inspections links
  info_block = report.parser.search("//table[@border='0']/tr[1]/td[1]")

  name = info_block.first.children.first.text
  street = info_block.children[2].text

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

  inspection_links = report.links.select { |l| l.href =~ /rim\.jsp\?q_ID=\d+/ }
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


      inspection = Inspection.new(:inspection_date => idate, :score => score.split(":").last.to_i,
                                  :url => i.href, :violations => violations)

      restaurant.inspections << inspection
      restaurant.save
    end
  end

end

url = "http://www.clackamas.us/healthapp/rim.jsp?q_ID=0310318B&q_iID=349213181"
run_parser(url)