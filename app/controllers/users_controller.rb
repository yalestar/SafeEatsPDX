class UsersController < ApplicationController
  def index
  end

  def show
  end

  def find_nearest
  	lat = params[:lat].to_f
  	long = params[:long].to_f
  	# rs = Restaurant.find({"loc" => {"$near" => [long, lat]}}, {:limit => 20})
  	
  	# TODO: this is really more of a metadata command
  	rs = MongoMapper.database.command({ 'geoNear' => 'restaurants', 'near' => [long,lat]})

  	# debugger
  	respond_to do |format|
  		format.js { render :json => rs['results'] }
  	end
  	
  end

end