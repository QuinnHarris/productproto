class AssertionRelation < Sequel::Model
  many_to_one :successor, class: :Assertion
  many_to_one :predecessor, class: :Assertion

  many_to_one :created_user, class: :User
  plugin :context, created_user: :user
end

class Assertion < Variable
  set_context_map created_user: :user

  one_to_many :predecessors, class: AssertionRelation, reciprocal: :successor
  one_to_many :successors, class: AssertionRelation, reciprocal: :predecessor
end

class ProductClass < Assertion

end

class Collection < Assertion

end

class InstanceCollection < Collection

end

class Product < Collection

end
