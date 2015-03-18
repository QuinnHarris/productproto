Value

class Property < PropertyValue
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale

  def self.set_value_class(key)
    @value_class = key

    one_to_many :property_values, class: key, key: :property_id, primary_key: :id
  end
  def self.value_class; @value_class; end
end
class PropertySingle < Property
end
class PropertySet < Property
end

class PropertyNull < Property
  set_value_class ValueNull
end


# Natural
class PropertyNaturalSingle < PropertySingle
  set_value_class ValueNatural
end
class PropertyNaturalSet < PropertySet
  set_value_class ValueNatural
end

# String
class PropertyStringSingle < PropertySingle
  set_value_class ValueString
end
class PropertyStringSet < PropertySet
  set_value_class ValueString
end

# Numbers
class PropertyFloatSingle < PropertySingle
  set_value_class ValueFloat
end
class PropertyIntegerSingle < PropertySingle
  set_value_class ValueInteger
end

class PropertyBoolean < PropertySingle
  set_value_class ValueBoolean
end

# Functions
class PropertyFunction < PropertySingle
  set_value_class Function
end
class PropertyFunctionDiscrete < PropertyFunction
  set_value_class FunctionDiscrete
end
