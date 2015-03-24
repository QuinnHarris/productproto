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
  def self.assert_dataset(assertion_table) #(basis)
    #Assertion
    #assertion_ds = AssertionRelation.decend_dataset(basis)
    #assertion_table = :assert_decend

    # First join predicates with assertion table selecting all rows that have
    # one id in assertion_dependent_ids matching an assertion id
    # For some reason doing this first makes the query much faster
    # GIN index lookups with a large set is slow.
    predicate_ds = dataset.join(assertion_table,
                                Sequel.pg_array_op(:assertion_dependent_ids).contains([:assert_decend__id]))
                    .select(Sequel::SQL::ColumnAll.new(table_name))
    predicate_table = :our_predicates
    ds = db.from(predicate_table).with(predicate_table, predicate_ds)

    # Filter
    #ds.from(predicate_table).where(
    ds = ds.where(
        Sequel.pg_array_op(:assertion_dependent_ids)
            .contained_by(Predicate.db.from(assertion_table).select(Sequel.function(:array_agg, :id))) )

    ds.join(:variables, :id => :value_id)
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

    ds = ds.with_recursive(cte_table, base_ds, r_ds)#.from(cte_table).select(*columns)


    refine_ds = db.from(cte_table).group(:value_id)
             .select(:value_id,
                     Sequel.function(:array_aggcat,
                                     Sequel.pg_array([Sequel.pg_array(:assertion_dependent_ids)
                                         .concat(:value_dependent_ids)])
                     ).as(:dependent_ids))

    #ds = ds.from_self
    variables_ds = db.from(refine_ds)
                       .join(:variables, :id => :value_id)
                       .join(:values, :id => :id)
                       .join(:variable_types, :id => :variables__type_id)
             .select(:variables__id, :type, :table, :dependent_ids, :property_id)
    variables_table = :our_variables

    ds = ds.with(variables_table, variables_ds)

    Property
    Function
    exprs = Value.descendants.map { |k| k.table_name.to_s }.uniq.map do |table_name|
      d = db.from(variables_table)
              .where(:table => table_name)
              .select(Sequel.qualify(variables_table, :id), :type, :dependent_ids, Sequel.qualify(variables_table, :property_id))
      if table_name == 'values'
        d.select_append(Sequel.as(nil, :value))
      else
        d = d.join(table_name, :id => :id)

        if table_name == 'functions'
          lateral_ds = db.from(
              FunctionDiscreteBreak.dataset.naked!
                  .where(:function_id => Sequel.qualify(table_name, :id))
                  .select(:minimums, :value).as(:r)
          ).select(Sequel.function(:json_agg, Sequel.function(:row_to_json, :r)).as(:value)).lateral

          d.join(lateral_ds, true).select_append(:value)
        else
          d.select_append(Sequel.function(:to_json, :value).as(:value))
        end
      end
    end

    values_ds = exprs[1..-1].inject(exprs.first) { |a, b| a.union(b, all: true, from_self: false) }
    values_table = :our_values

    ds = ds.with(values_table, values_ds)


    lateral_ds = db.from(db.from(values_table)
                             .where(:properties__id => :property_id)
                             .select(:id, :type, :dependent_ids, :value).as(:r))
                     .select(Sequel.function(:json_agg, Sequel.function(:row_to_json, :r)).as(:values)).lateral

    properties_js_ds = ds.from(
        db.from(:properties).join(:variables, :id => :id).join(:variable_types, :id => :type_id)
            .where(:properties__id => db.from(values_table).select(:property_id)).join(lateral_ds, true)
            .select(:properties__id, :type, :value, :values).as(:r)
    ).select(Sequel.function(:json_agg, Sequel.function(:row_to_json, :r))).as(:properties)

    # # Screws up the query plan, does sequential search over variables!
    # assertions_js_ds = db.from(assertion_table
    #     db.from(assertion_table).join(:variables, :id => :id).join(:variable_type_map, :id => :type)
    #                          .select(:variables__id, Sequel.as(:name, :type), :access, :depth).as(:r)
    # ).select(Sequel.function(:json_agg, Sequel.function(:row_to_json, assertion_table))).as(:assertions)

    assertions_js_ds = db.from(assertion_table).select(Sequel.function(:array_agg, :id)).as(:assertion_ids)

    ds.from(db.select(assertions_js_ds, properties_js_ds).as(:r)).select(Sequel.function(:row_to_json, :r))
  end

  # !!! IMPLEMENT
  def remove

  end
end
