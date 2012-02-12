require 'nokogiri'

uri = "/Users/yalestar/Yale/SafeEatsPDX/testpage.html"
f = File.open(uri)
page = Nokogiri::HTML(f)
bottom_table = page.search("//table[@border='0']/tr[2]/td/table")
f.close

bottom_table.each do |cell|
    kids = cell.children.search("td")
    insp_type = kids.shift.text
    score = kids.shift.text
    kids.shift
    kids.shift

    # vios = kids[2].text # just the text Violations (the column header)
    # puds = kids[3].text # also just a header
    # puts "VIOS: #{vios}"
    # puts "PUDS: #{puds}"
	kids.each_slice(2) do |k|
		vio=  k.first.text
		ded=  k.last.text
		puts vio
	end           
end
