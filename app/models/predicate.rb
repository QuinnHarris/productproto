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

  # Doin JSON SELECT json_agg(row_to_json(t)) FROM * t
  def self.decend_dataset(basis)
    Assertion
    base_ds = AssertionRelation.decend_dataset(basis)

    base_ds = base_ds.select(Sequel.cast(nil, :integer).as(:id),
                             Sequel.as(:id, :value_id),
                             Sequel.cast(Sequel.pg_array([]), 'integer[]').as(:dependent_ids),
                             Sequel.as(false, :deleted),
                             Sequel.cast(nil, :integer).as(:created_user_id),
                             Sequel.cast(nil, :timestamp).as(:created_at),
                             #Sequel.as(0, :recurse_depth),
                             Sequel.function(:array_agg, :id).over().as(:asserted_ids),
                             Sequel.cast(Sequel.pg_array([]), 'integer[]').as(:predicate_ids),
    )

    cte_table = :predicate_recurse

    array_agg_ds = db.from(cte_table)
                       .select(#Sequel.+(:recurse_depth, 1).as(:recurse_depth),
                               :asserted_ids, :predicate_ids)
                       .limit(1)
                       .as(:agg)


    r_ds = self.dataset.join(array_agg_ds,
                             Sequel.pg_array_op(:asserted_ids)
                                 .contains(:dependent_ids))
            .where(:id => Sequel.pg_array_op(:predicate_ids).all).invert


    r_ds = r_ds.from_self.select(*columns, #:recurse_depth,
                          Sequel.pg_array_op(Sequel.function(:array_agg, :value_id).over()).concat(:asserted_ids).as(:asserted_ids),
                          Sequel.pg_array_op(Sequel.function(:array_agg, :id).over()).concat(:predicate_ids).as(:predicate_ids)
    )

    ds = db.from(cte_table).with_recursive(cte_table, base_ds, r_ds).select(*columns)

    #ds = ds.group(:value_id).select(:value_id,
    #                                Sequel.function(:array_aggcat,
    #                                                Sequel.pg_array([:dependent_ids])).as(:dependent_set))

    #ds = ds.from_self.join(:variables, :id => :value_id).select(:id, :type, :dependent_set)


  end

  # !!! IMPLEMENT
  def remove

  end
end
