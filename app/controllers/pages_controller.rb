class PagesController < ApplicationController
  include HighVoltage::StaticPage

  layout 'pages'
end
