namespace :parsers do
	desc "Clackamas County parser"
	task :clackamas => :environment do
		require 'clackamas_parser'
		ClackamasParser.run_parser
	end
end