class BusinessAddress < Sequel::Model(:sales__business_address)
  many_to_one :business
end
