namespace :clackamas do
	
	desc "Clackamas County parser"
	task :parser => :environment do
		require 'clackamas_parser'
		ClackamasParser.run_parser
	end

	desc "Clackamas geocoder"
	task :geocoder => :environment do
		require 'clackamas_parser'
				
	end

end