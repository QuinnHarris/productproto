class GivenEmail < Sequel::Model(:sales__given_emails)
  many_to_one :access_request
end
