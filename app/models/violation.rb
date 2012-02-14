class Violation
	include MongoMapper::EmbeddedDocument
	belongs_to :inspection

	key :violation_text, String
	key :violation_comments, String
	key :corrective_text, String
	key :corrective_comments, String
	key :point_deduction, Float
	key :rule, String
				# for multnomah: :rule_violations = violation_text
end