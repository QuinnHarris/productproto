class AccessSession < Sequel::Model(:access__sessions)
  one_to_many :requests, class: AccessRequest
end
