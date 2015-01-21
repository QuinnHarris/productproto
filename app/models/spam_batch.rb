class SpamBatch < Sequel::Model
  one_to_many :spam_emails
end
