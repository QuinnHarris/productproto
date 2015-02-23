class GivenEmail < Sequel::Model(:sales__given_email)
  many_to_one :access_requests
end
