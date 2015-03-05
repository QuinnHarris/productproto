class Predicate < Sequel::Model
  plugin :context, created_user: :user
  plugin :pg_array_associations

  many_to_one :value
  pg_array_to_many :dependents, class: :Variable
  def dependents=(list)
    ids = list.map do |obj|
      raise "Unexpected type" unless obj.is_a?(Variable)
      obj.id
    end
    set_column_value("dependent_ids=", Sequel.pg_array(ids))
  end

  many_to_one :created_user, class: :User
end
