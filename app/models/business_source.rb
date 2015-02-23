class BusinessSource < Sequel::Model(:sales__business_source)
  set_primary_key [:business_id, :source_id]
  many_to_one :business
  many_to_one :source
end
