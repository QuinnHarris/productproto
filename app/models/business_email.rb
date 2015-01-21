class BusinessEmail < Sequel::Model
  many_to_one :business
  one_to_many :spam_emails
end
