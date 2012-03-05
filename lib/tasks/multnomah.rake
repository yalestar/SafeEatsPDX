namespace :multnomah do

	desc "Multnomah County parser"
	task :parser => :environment do
		require 'multnomah_parser'
		MultnomahParser.fetch_restaurants
	end

	desc "Fetch Multnomah inspections"
	task :get_inspections => :environment do
		require "multnomah_parser"
		MultnomahParser.fetch_inspections
	end

	desc "Multnomah geocoder"
	task :geocoder => :environment do
		require "multnomah_parser"
		MultnomahParser.geocode_multnomah
	end

	desc "Multnomah geocoder"
	task :yahoo_geocoder => :environment do
		require "multnomah_parser"
		MultnomahParser.yahoo_geocode
	end

	task :geokit => :environment do
		require "multnomah_parser"
		MultnomahParser.geokit_geocode
	end

	desc "Fix locations"
	task :fix_geo => :environment do
		Restaurant.where(:county => "Multnomah").each do |r|
			r.loc = r.loc.reverse
			r.save
		end
	end
end