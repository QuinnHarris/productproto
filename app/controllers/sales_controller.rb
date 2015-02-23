class SalesController < ApplicationController
  def given_email
    ge = GivenEmail.create(access_request: @request, value: params[:email])

  end
end
