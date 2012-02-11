class Inspection
	include MongoMapper::EmbeddedDocument
  
  	belongs_to :restaurant
  
  	  key :restaurant_id, Integer
      key :inspection_date, Time
      key :score, Integer
      key :url, String
      key :notes, String
end
