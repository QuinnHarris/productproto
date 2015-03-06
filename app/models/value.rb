class Value < PropertyValue
  one_to_many :predicates

  def predicate_on(*list)
    Predicate.create(value: self, dependents: list.flatten)
  end
end

class ValueNull < Value
  set_context_map
end

class ValueNatural < Value
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale
end

class ValueString < Value
  set_primary_key [:id, :created_at]
  set_context_map created_user: :user
end

class ValueFloat < Value
  set_primary_key [:id, :created_at]
end

class ValueInteger < Value
  set_primary_key [:id, :created_at]
end


# Pricing is a specific property value
class Pricing < Value
end

class PriceSingle < Pricing
end

class PriceDiscrete < Pricing
end
class PriceReplaceDiscrete < PriceDiscrete
end
class PriceAddDiscrete < PriceDiscrete
end
class PriceMultiplyDiscrete < PriceDiscrete
end

class PriceDiscreteBreak < Sequel::Model
end

class PriceInput < Sequel::Model
end