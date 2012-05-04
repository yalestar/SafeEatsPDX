require 'net/https'

puts "Hello World"



x = Net::HTTP.get(URI.parse("http://www.clark.wa.gov/public-health/food/list.asp"),nil)
inspectionids = Array.new
#puts "body is: [#{x}]\n"
x.split("'").each do |token|
	if token.start_with?("FA")
		inspectionids << token
		puts("token is: #{token}")
	end
end


inspectionids.each do |inspect|
params = Hash.new
params[:selection] = inspect


x = Net::HTTP.post_form(URI.parse("http://www.clark.wa.gov/public-health/food/multilist.asp"),params)

#puts "body is: [#{x.body}]\n"
nexttdhasbusiness = false
getbusiness = false
getfirsttotal = true
nexttdhasinspection = false
getinspectiondate = false
gotinspectiondate = false
x.body.split(">").each do |token|
	if token.include?("Business Name")
		nexttdhasbusiness = true
	end
        if getbusiness
		puts("business name is #{token}")
		getbusiness = false
		nexttdhasbusiness = false
	end
	if nexttdhasbusiness && token.include?("td width")
		getbusiness = true
	end
	if token.include?("Total :") && getfirsttotal
		getfirsttotal = false
		puts("Total deduction is #{token}")
	end
	if getinspectiondate
		puts("Inspection date is #{token}")
		gotinspectiondate = true
		nexttdhasinspection = false
		getinspectiondate = false
	end
 	if nexttdhasinspection && token.include?("td")
		getinspectiondate = true
	end
	if token.include?("Inspection/Site Visit") && !gotinspectiondate
		nexttdhasinspection = true
	end
end
   sleep 5
end

