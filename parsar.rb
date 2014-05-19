require 'nokogiri'
require 'open-uri'
require 'mechanize'

def run_parser(url)
  agent = Mechanize.new
  page = agent.get(url)

  # submit the form with no criteria
  report = page.forms.first.submit
  inspection_links = report.links.select { |l| l.href =~ /rim\.jsp\?q_ID=\d+/ }

  inspection_links.first(10).each do |i|
  
    restaurant_page = i.click
    # main info is in the first p tag
    info_block = restaurant_page.search("//p[1]")
    name = info_block.children.first.text.strip    
    street = info_block.children[2].text.strip
    if !info_block.children[4].text.empty?
      csz = info_block.children[4].text.strip
    else
      csz = info_block.children[5].text.strip
    end
    
    puts "#{name} ->>>>   #{street} #{csz}"
  end


  # # spaces in the returned string are actually nbsp
  # nbsp = Nokogiri::HTML("&nbsp;").text
  # csz.gsub!(nbsp, " ")

  # county = "Clackamas"
  # state = "OR"

  # r = nil
  # if m = csz.match(/([A-Z ]*), (OR) (97\d{3})/)
  #   city = titleize(m[1]).strip
  #   zip = m[3]
  #   # restaurant = Restaurant.create(:name => name, :street => street,
  #   #                                :city => city, :state => state,
  #   #                                :zip => zip, :county => county)
  #   # puts "#{name}: #{street} #{city}, #{state}, #{county}, #{zip}"
  # else
  #   # restaurant = Restaurant.create(:name => name, :state => state, :county => county)
  #   puts "#{name}: #{street} #{city}, #{state}, #{county}, #{zip}"

  # end


end

url = "http://web3.clackamas.us/healthapp/ri.jsp"
run_parser(url)