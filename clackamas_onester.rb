require 'nokogiri'
require 'open-uri'
require 'mechanize'

def titleize(str)
  str.split(/(\W)/).map(&:capitalize).join
end

def run_parser(url)
  agent = Mechanize.new
  page = agent.get(url)

  # submit the form with no criteria
  report = page.forms.first.submit

  # main info is in the first p tag
  info_block = report.parser.search("//p[1]")

  name = info_block.first.children.first.text
  street = info_block.children[2].text

  if !info_block.children[4].text.empty?
    csz = info_block.children[4].text.strip
  else
    csz = info_block.children[5].text.strip
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
    # restaurant = Restaurant.create(:name => name, :street => street,
    #                                :city => city, :state => state,
    #                                :zip => zip, :county => county)
    puts "name: #{name}"
    puts "street: #{street}"
    puts "city: #{city}"
    puts "state: #{state}"
    puts "zip: #{zip}"
  else
    # restaurant = Restaurant.create(:name => name, :state => state, :county => county)
    puts "name: #{name}"
    puts "street: #{street}"
    puts "city: #{city}"
    puts "state: #{state}"
    puts "zip: #{zip}"
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

        # violations << Violation.new(:violation_text => vio, :point_deduction => pd)
        puts "-------- VIOLATIONS ---------"
        puts "vio_text: #{vio}"
        puts "pd: #{pd}"
      end

      score = score.split(":").last.to_i
      inspection = Inspection.new(:inspection_date => idate, :score => score,
                                  :url => i.href, :violations => violations)
      puts "========== INSPECTIONS ============"
      puts "idate: #{idate}"
      puts "score: #{score}"
      puts "url: #{url}"
      # restaurant.inspections << inspection
      # restaurant.save
    end
  end

end

url = "http://web3.clackamas.us/healthapp/ri.jsp"
run_parser(url)