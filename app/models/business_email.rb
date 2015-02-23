class BusinessEmail < Sequel::Model(:sales__business_email)
  many_to_one :business
  one_to_many :spam_emails
end
