namespace :multnomah do

	desc "Multnomah County parser"
	task :parser => :environment do
		require 'multnomah_parser'
		MultnomahParser.run_parser
	end

	desc "Multnomah geocoder"
	task :geocoder => :environment do
		require 'multnomah_parser'
		MultnomahParser.geocode_multnomah
	end
	task :geokit => :environment do
		require 'multnomah_parser'
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