namespace :clackamas do
	
	desc "Clackamas County parser"
	task :parser => :environment do
		require 'clackamas_parser'
		ClackamasParser.run_parser
	end

	desc "Clackamas google geocoder"
	task :google_geocoder => :environment do
		require 'clackamas_parser'
		ClackamasParser.google_geocode		
	end

	desc "Clackamas yahoo geocoder"
	task :yahoo_geocoder => :environment do
		require 'clackamas_parser'
		ClackamasParser.yahoo_geocode		
	end

end