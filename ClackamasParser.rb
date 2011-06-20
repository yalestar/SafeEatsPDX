class ClackamasParser
  require 'nokogiri'
  require 'open-uri'
  require 'mechanize'

  url = "http://www.co.clackamas.or.us/foodinspection/ris.php"
  agent = Mechanize.new
  page = agent.get(url)
  form = page.form('ris')
  # TODO: some sort of alert if the page DOM changes at all
  full_list = form.submit
  
  link_root = "http://www.co.clackamas.or.us/foodinspection/"

  all_links = full_list.links.select{|l| l.href =~ /risreport\.php\?q_ID=\d+/ }
  
  # all_links.first(5).each do |l|
  fl = all_links.first
  report = fl.click
  #  the first tr's first td is 4 lines with the contact info separated by br
  #  the second td is a list of the inspections links
  info_block = report.parser.search("//table[@border='0']/tr[1]/td[1]")
  # ^ is a NodeSet

    # Node
    puts info_block.first.children.first.text
    puts info_block.children[2].text
    puts info_block.children[4].text
  
end
