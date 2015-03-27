# Pricing is a specific property value
class Function < Value
  many_to_many :scope_properties, class: Property, table: :function_scopes
  one_to_many :inputs, class: :FunctionInput
end

class FunctionInput < Sequel::Model
  many_to_one :function
end


class FunctionDiscrete < Function
  one_to_many :breaks, class: :FunctionDiscreteBreak, order: [:argument, :minimum]

  # Set Price
  def value=(hash)
    db.transaction do
      save if new? # Need ID for foreign key reference
      hash.each do |minimums, value|
        brk = FunctionDiscreteBreak.new(function: self, value: value)
        brk.send(:set_restricted, { minimums: minimums }, [:minimums])
        brk.save
      end
    end
  end

  # Similar to import description.rb
  def value
    breaks.each_with_object({}) do |brk, hash|
      hash[brk.minimums.to_a] = brk.value
    end
  end

  def self.value_valid?(value)
    return false unless value.is_a?(Hash)
    value.each do |list, value|
      return false unless value.is_a?(Fixnum)
      return false unless list.is_a?(Array)
      list.each { |i| return false unless i.is_a?(Fixnum) }
    end
    true
  end
end

class FunctionDiscreteBreak < Sequel::Model
  plugin :context, created_user: :user

  many_to_one :function, class: :FunctionDiscrete

  many_to_one :created_user, class: :User
end

class FunctionDiscreteReplace < FunctionDiscrete
end
class FunctionDiscreteAdd < FunctionDiscrete
end
class FunctionDiscreteMultiply < FunctionDiscrete
end
