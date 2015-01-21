class AccessRequest < Sequel::Model(:access__requests)
  many_to_one :session, class: AccessSession

  one_through_one :spam_email
end
