class SpamBatch < Sequel::Model(:sales__spam_batch)
  one_to_many :spam_emails
end
