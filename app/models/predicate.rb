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

  def self.decend_dataset(basis)
    Assertion
    base_ds = AssertionRelation.decend_dataset(basis)

    base_ds = base_ds.select(Sequel.as(:id, :value_id),
                             Sequel.cast(Sequel.pg_array([]), 'integer[]').as(:dependent_ids),
                             Sequel.as(0, :recurse_depth),
                             Sequel.function(:array_agg, :id).over().as(:asserted_ids),
    )

    cte_table = :predicate_recurse

    array_agg_ds = db.from(cte_table)
                       .select(Sequel.+(:recurse_depth, 1).as(:recurse_depth), :asserted_ids)
                       .limit(1)
                       .as(:agg)


    r_ds = self.dataset.join(array_agg_ds,
                             Sequel.pg_array_op(:asserted_ids)
                                 .contains(:dependent_ids))

    #r_ds = r_ds.select(Sequel.as(:value_id, :id), :dependent_id)

    r_ds = r_ds.from_self.select(:value_id, :dependent_ids, :recurse_depth,
                          Sequel.function(:array_agg, :value_id).over().as(:asserted_ids) )

    ds = db.from(cte_table).with_recursive(cte_table, base_ds, r_ds, union_all: false)

   # ds = ds.join(:variables, :id => :id)


  end
end
