class RestaurantsController < ApplicationController

  def testpage
    
  end
  
  def index
  end

  def show
  end

  def find_nearest
  	lat = params[:lat].to_f
  	long = params[:long].to_f
  	# rs = Restaurant.find({"loc" => {"$near" => [long, lat]}}, {:limit => 10})
  	
  	# TODO: this is really more of a metadata command
  	# rs = MongoMapper.database.command({ 'geoNear' => 'restaurants', 'near' => [long,lat]}, :num => 5)
    center = [long, lat]
    radius = 0.01
    debugger
    rs = Restaurant.where(:loc => {'$near' => center, '$maxDistance' => radius}).limit(10).all
  	respond_to do |format|
  		format.js { render :json => rs }
  	end
  	
  end

  def name_search
    rname = params[:name]
    # rs = Restaurant
  end

end
