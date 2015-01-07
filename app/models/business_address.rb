class BusinessAddress < Sequel::Model
  many_to_one :business
end
