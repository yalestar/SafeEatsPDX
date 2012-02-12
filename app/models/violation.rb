class Violation
	include MongoMapper::EmbeddedDocument
	belongs_to :inspection

	key :violation_text, String
	key :point_deduction, Float
end