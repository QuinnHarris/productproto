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

class ValueBoolean < Value
  set_primary_key [:id, :created_at]
  set_context_map created_user: :user
end
