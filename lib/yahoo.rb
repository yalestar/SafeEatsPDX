require 'open-uri'

yk = "zJTs83vV34Eev5u7qgZIhICrZ0f20bNkRyvl9_XZmMMygNWXkDscK.z030x6UB4-"

ungeocoded = Restaurant.where(:county => "Multnomah", :loc => {'$size' => 0 }).limit(10)
# http://where.yahooapis.com/geocode?location=San+Francisco,+CA&flags=J&appid=yourappid
ungeocoded.each do |r|
	puts r.address
end