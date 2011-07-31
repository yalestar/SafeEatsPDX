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

  all_links.first(5).each do |l|
    # fl = all_links.first
    report = l.click
    # the first tr's first td is 4 lines with the contact info separated by br
    # the second td is a list of the inspections links
    # xpath ignores tbody for some reason
    # we're essentially parsing this:
    # http://www.co.clackamas.or.us/foodinspection/risreport.php?q_ID=0310774B&q_iID=96517741
    info_block = report.parser.search("//table[@border='0']/tr[1]/td[1]")
    inspections_block = report.parser.search("//table[@border='0']/tr[1]/td[2]")
    
    # Node
    name = info_block.first.children.first.text #name
    street = info_block.children[2].text #street addr
    csz = info_block.children[4].text # city state zip
    puts "-"*40
    puts name
    puts street
    puts csz.gsub("\r\n", "")

    
    inspections = inspections_block.children.each do |i|
      if i.is_a?(Nokogiri::XML::Text) && !(i.text.strip =~ /\(\d+\)/.nil?) 
        score = i.text.gsub("(", "").gsub(")", "")
        puts score  
      elsif i.is_a?(Nokogiri::XML::Element) && i.name == 'a'
        report_link = i.attributes["href"].value
        puts report_link
      end

    end
  end


end
