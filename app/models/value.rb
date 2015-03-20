class Value < PropertyValue
  one_to_many :predicates

  def predicate_on(*list)
    Predicate.create(value: self, dependents: list.flatten)
  end

  def self.value_transform(value); value; end
end

class ValueNull < Value
  set_context_map
end

class ValueNatural < Value
  set_primary_key [:id, :locale_id, :created_at]
  many_to_one :locale

  def self.value_valid?(value)
    value.is_a?(String)
  end
end

class ValueString < Value
  set_primary_key [:id, :created_at]
  set_context_map created_user: :user

  def self.value_valid?(value)
    value.is_a?(String)
  end
end

class ValueFloat < Value
  set_primary_key [:id, :created_at]

  def self.value_valid?(value)
    value.is_a?(Fixnum) || value.is_a?(Float)
  end
end

class ValueInteger < Value
  set_primary_key [:id, :created_at]

  def self.value_valid?(value)
    value.is_a?(Fixnum)
  end
end

class ValueBoolean < Value
  set_primary_key [:id, :created_at]
  set_context_map created_user: :user

  def self.value_valid?(value)
    value == false || value == true
  end

  def self.value_transform(value)
    return value if value_valid?(value)
    return unless value.is_a?(String)
    value = value.downcase
    return true if %w(true yes).include?(value)
    return false if %w(false no).include?(value)
    nil
  end
end
