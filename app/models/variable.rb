class Variable < Sequel::Model
  # Only Append, index is relevant
  table_map = {
      Predicate: :predicates,
      PredicateOr: :predicates_or,
      Property: :properties,
      AbstractValue: :values,
      Value: :values,
      Pricing: :pricing,
      Instance: :instances,
      Collection: :collections,
      InstanceCollection: :collections,
      Product: :collections,
  }

  model_map = {}; table_map.each_with_index { |(c, t), i| model_map[i] = c }
  plugin :class_table_inheritance, key: :type, table_map: table_map, model_map: model_map
end

class Collection < Variable

end

class InstanceCollection < Collection

end

class Product < Collection

end


class Value < Variable

end

class Instance


class Property < Variable

end

class PredicateOr < Variable

end

class Localized < Variable

end

class AbstractValue < Predicate
  # Composing function, default replace
end

class Value < AbstractValue
  many_to_one :property
end

# Pricing is a specific property value
class Pricing < AbstractValue

end

class PricingBreak < Pricing

end

# Should this be a PredicateRelation instead of a Predicate?
class Instance < Predicate

end


# Variable
# |- PropertyValue (versioned)
# |  |- Value : no children (by Variable Inherit)
# |  |- Property : children (by Variable Inherit)
# |- Instance
# |- Pricing (mix with Value)
# |- Collection
# |  |- Product
# |  |- InstanceCollection