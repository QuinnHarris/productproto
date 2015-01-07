class BusinessEmail < Sequel::Model
  many_to_one :business
end
