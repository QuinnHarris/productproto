class Variable < Sequel::Model
  # Only Append, index is relevant
  type_map = {
      PropertySingleNatural: :value_naturals,
      PropertySingleString: nil,
      PropertySingleFloat: nil,
      PropertySingleInteger: nil,
      PropertySetNatural: [nil, 1 * 2**8],
      PropertySetString: nil,

      ValueNatural: [:value_naturals, 8 * 2**8],
      ValueString: :value_strings,
      ValueFloat: :value_floats,
      ValueInteger: :value_integers,

      PriceSingle: [:price_singes, 9 * 2**8],
      PriceReplaceDiscrete: :prices,
      PriceAddDiscrete: nil,
      PriceMultDiscrete: nil,

      Collection: [:variables, 16 * 2**8],
      InstanceCollection: nil,
      Product: nil,

      Instance: [:value_integers, 17 * 2**8 + 1],
      #Variable: :variables,
  }

  table_map = {}
  model_map = {}
  index = 0
  table = nil
  type_map.each do |c, v|
    t, i = Array(v)
    index = i || index
    table = t || table
    table_map[c] = table
    model_map[index] = c
    index += 1
  end
  plugin :improved_class_table_inheritance, key: :type, table_map: table_map, model_map: model_map
end

class Collection < Variable

end

class InstanceCollection < Collection

end

class Product < Collection

end


class AbstractPropertyValue < Variable

end

class AbstractProperty < AbstractPropertyValue
end
class AbstractSingleProperty < AbstractPropertyValue
end
class AbstractSetProperty < AbstractPropertyValue
end

class AbstractValue < AbstractPropertyValue
end

class PropertySingleNatural < AbstractSingleProperty
end
class PropertySetNatural < AbstractSetProperty
end
class ValueNatural < AbstractValue
end

class PropertySingleString < AbstractSingleProperty
end
class PropertySetString < AbstractSetProperty
end
class ValueString < AbstractValue
end

class PropertySingleFloat < AbstractSingleProperty
end
class ValueFloat < AbstractValue
end

class PropertySingleInteger < AbstractSingleProperty
end
class ValueInteger < AbstractValue
end

class Instance < Variable

end

# Pricing is a specific property value
class AbstractPricing < AbstractValue

end

class PriceSingle < AbstractPricing

end

class PriceDiscrete < AbstractPricing
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



# Variable
# |- PropertyValue (versioned)
# |  |- Value : no children (by Variable Inherit)
# |  |- Property : children (by Variable Inherit)
# |- Instance
# |- Pricing (mix with Value)
# |- Collection
# |  |- Product
# |  |- InstanceCollection