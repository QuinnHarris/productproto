class BusinessSource < Sequel::Model
  set_primary_key [:business_id, :source_id]
  many_to_one :business
  many_to_one :source
end
