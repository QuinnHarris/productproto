class Predicate < Sequel::Model
  plugin :context, created_user: :user
  plugin :pg_array_associations

  many_to_one :value
  pg_array_to_many :assertion_dependents, class: :Assertion
  pg_array_to_many :value_dependents, class: :Variable
  def dependents=(list)
    assertion_ids = []
    value_ids = []
    list.each do |obj|
      raise "Unexpected type" unless obj.is_a?(Variable)
      if obj.is_a?(Assertion)
        assertion_ids << obj.id
      else
        value_ids << obj.id
      end
    end
    set_column_value("assertion_dependent_ids=", Sequel.pg_array(assertion_ids))
    set_column_value("value_dependent_ids=", Sequel.pg_array(value_ids))
  end
  def dependents
    assertion_dependents + value_dependents
  end

  many_to_one :created_user, class: :User

  # def self.assert_dataset(basis)
  #   Assertion
  #   assertion_ds = AssertionRelation.decend_dataset(basis)
  #
  #   Predicate.dataset.where(
  #       Sequel.pg_array_op(:assertion_dependent_ids)
  #           .contained_by(assertion_ds.select(Sequel.function(:array_agg, :id))) )
  # end

  # Believed to be the same as the above version but runs faster 4s vs 16s
  def self.assert_dataset(basis)
    Assertion
    assertion_ds = AssertionRelation.decend_dataset(basis)
    assertion_table = :assert_decend

    # First join predicates with assertion table selecting all rows that have
    # one id in assertion_dependent_ids matching an assertion id
    # For some reason doing this first makes the query much faster
    # GIN index lookups with a large set is slow.
    predicate_ds = dataset.join(assertion_table,
                                Sequel.pg_array_op(:assertion_dependent_ids).contains([:assert_decend__id]))
                    .select(Sequel::SQL::ColumnAll.new(table_name))
    predicate_table = :our_predicates
    ds = assertion_ds.with(predicate_table, predicate_ds)

    # Filter
    ds.from(predicate_table).where(
        Sequel.pg_array_op(:assertion_dependent_ids)
            .contained_by(Predicate.db.from(assertion_table).select(Sequel.function(:array_agg, :id))) )
#      .select(Sequel::SQL::ColumnAll.new(predicate_table))
  end

  # Doin JSON SELECT json_agg(row_to_json(t)) FROM * t
  def self.decend_dataset(basis)
    Assertion
    assertion_ds = AssertionRelation.decend_dataset(basis)
    assertion_table = :assert_decend

    predicate_ds = Predicate.dataset.where(
        Sequel.pg_array_op(:assertion_dependent_ids)
            .contained_by(Predicate.db.from(assertion_table).select(Sequel.function(:array_agg, :id))) )
    predicate_table = :our_predicates
    ds = assertion_ds.with(predicate_table, predicate_ds)


    base_ds = db.from(assertion_table)
                  .select(Sequel.cast(nil, :integer).as(:id),
                          Sequel.as(:id, :value_id),
                          Sequel.cast(nil, 'integer[]').as(:assertion_dependent_ids),
                          Sequel.cast(nil, 'integer[]').as(:value_dependent_ids),
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


    r_ds = db.from(predicate_table).join(array_agg_ds,
                             Sequel.pg_array_op(:asserted_ids)
                                 .contains(:value_dependent_ids))
            .where(:id => Sequel.pg_array_op(:predicate_ids).all).invert


    r_ds = r_ds.from_self.select(*columns, #:recurse_depth,
                          Sequel.pg_array_op(Sequel.function(:array_agg, :value_id).over()).concat(:asserted_ids).as(:asserted_ids),
                          Sequel.pg_array_op(Sequel.function(:array_agg, :id).over()).concat(:predicate_ids).as(:predicate_ids)
    )

    ds = ds.with_recursive(cte_table, base_ds, r_ds).from(cte_table).select(*columns)


    #ds = ds.group(:value_id).select(:value_id,
    #                                Sequel.function(:array_aggcat,
    #                                                Sequel.pg_array([:dependent_ids])).as(:dependent_set))

    #ds = ds.from_self.join(:variables, :id => :value_id).select(:id, :type, :dependent_set)


  end

  # !!! IMPLEMENT
  def remove

  end
end
