class User < Assertion
  many_to_one :locale
  one_to_many :authenticates
end
