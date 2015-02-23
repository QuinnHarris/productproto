class SalesController < ApplicationController
  def given_email
    ge = GivenEmail.create(access_request: @request, value: params[:email][:value])

    respond_to do |format|
      format.json { render :json => { success: true } }
    end
  end
end
