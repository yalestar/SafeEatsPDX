require 'net/https'

x = Net::HTTP.get(URI.parse("http://www.clark.wa.gov/public-health/food/list.asp"), nil)
inspection_ids = Array.new
#puts "body is: [#{x}]\n"
x.split("'").each do |token|
  if token.start_with?("FA")
    inspection_ids << token
    puts("token is: #{token}")
  end
end


inspection_ids.each do |inspect|
  params = Hash.new
  params[:selection] = inspect


  site_url = 'http://www.clark.wa.gov/public-health/food/multilist.asp'
  x = Net::HTTP.post_form(URI.parse(site_url), params)

#puts "body is: [#{x.body}]\n"
  next_td_has_business = false
  get_business = false
  get_first_total = true
  next_td_has_inspection = false
  get_inspection_date = false
  got_inspection_date = false
  x.body.split(">").each do |token|
    if token.include?("Business Name")
      next_td_has_business = true
    end
    if get_business
      puts("business name is #{token}")
      get_business = false
      next_td_has_business = false
    end
    if next_td_has_business && token.include?("td width")
      get_business = true
    end
    if token.include?("Total :") && get_first_total
      get_first_total = false
      puts("Total deduction is #{token}")
    end
    if get_inspection_date
      puts("Inspection date is #{token}")
      got_inspection_date = true
      next_td_has_inspection = false
      get_inspection_date = false
    end
    if next_td_has_inspection && token.include?("td")
      get_inspection_date = true
    end
    if token.include?("Inspection/Site Visit") && !got_inspection_date
      next_td_has_inspection = true
    end
  end
  sleep 5
end

