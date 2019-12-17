class HomeController < ApplicationController
	def home
		respond_to do |format|
      format.html { render json: "hello" }
      format.json { render json: {message: "hello"} }
    end
	end
end
