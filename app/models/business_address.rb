class BusinessAddress < Sequel::Model(:sales__business_addresses)
  many_to_one :business
end
