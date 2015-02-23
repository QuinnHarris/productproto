class SpamBatch < Sequel::Model(:sales__spam_batches)
  one_to_many :spam_emails
end
