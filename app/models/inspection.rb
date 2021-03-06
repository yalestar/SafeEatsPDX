class Inspection
	include MongoMapper::EmbeddedDocument
  
  	belongs_to :restaurant
  	many :violations

  	key :inspection_id, Integer
  	key :inspection_type, String
  	key :inspection_date, Time
  	key :inspection_name, String
  	key :score, Integer
  	key :url, String
  	key :notes, String
end
