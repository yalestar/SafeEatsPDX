class Restaurant < ActiveRecord::Base
  
  has_many :inspections
end
