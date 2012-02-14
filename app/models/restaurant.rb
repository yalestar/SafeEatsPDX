class Restaurant
  include MongoMapper::Document

  many :inspections

     key :name, String, :required => true
     key :street, String
     key :city, String
     key :county, String
     key :state, String
     key :zip, String
     key :loc, Array

     def address
     	"#{self.street}, #{self.city}, #{self.state} #{self.zip}"
     end

end
