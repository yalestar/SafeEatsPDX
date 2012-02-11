class Inspection
	include MongoMapper::EmbeddedDocument
  
  	belongs_to :restaurant
  
      key :inspection_date, Time
      key :score, Integer
      key :url, String
      key :notes, String
      key :violations
      key :point_deductions
end
