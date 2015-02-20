module Sequel
  class Database
    # Ideally this would be submitted to the Sequel project
    def create_sequence_sql(name, options)
      # Need to implement INCREMENT, MINVALUE, MAXVALUE, START, CACHE, CYCLE
      sql = "CREATE #{temporary_table_sql if options[:temp]}SEQUENCE #{options[:temp] ? quote_identifier(name) : quote_schema_table(name)}"
      sql += " INCREMENT BY #{options[:increment]}" if options[:increment]
      sql += " MINVALUE #{options[:minvalue]}" if options[:minvalue]
      sql += " MAXVALUE #{options[:maxvalue]}" if options[:maxvalue]
      sql += " START WITH #{options[:start]}" if options[:start]
      sql += " CACHE #{options[:cache]}" if options[:cache]
      sql += " CYCLE" if options[:cycle]
      sql += " OWNED BY #{options[:ownedby_table]}.#{options[:ownedby_column]}" if options[:ownedby_table]
      sql
    end

    def create_sequence(name, options=OPTS)
      run(create_sequence_sql(name, options))
    end
  end
end


Sequel.migration do
  change do

    create_table :locales do
      primary_key :id
      String      :name
    end

    create_table :variables do
      primary_key :id
      Integer     :record_id
      index       :record_id
      Integer     :type # Predicated on record_id
      DateTime    :created_at, null: false
      #TrueClass   :deleted, null: false, default: false
    end

    create_sequence('variables_record_id_seq',
                    ownedby_table: :variables,
                    ownedby_column: :record_id)
    set_column_default(:variables, :record_id, Sequel.function(:nextval, 'variables_record_id_seq'))

    create_table :predicates do
      foreign_key :id, :variables, null: false
    end

    create_table :predicate_relations do
      primary_key :id
      foreign_key :predicate_record_id, :predicates, key: :record_id, null: false
      TrueClass   :deleted, null: false, default: false
      DateTime    :created_at, null: false
    end

    create_table :predicate_and do
      foreign_key :variable_record_id, :variables, key: :record_id, null: false
      foreign_key :relation_id, :predicate_relations, null: false
    end


    create_table :properties do
      foreign_key :id, :variables, null: false
      foreign_key :locale_id, :locales, null: false
      String      :name
    end

    create_table :values do
      foreign_key :id, :predicates, null: false
      foreign_key :property_id, :properties, null: false
      foreign_key :locale_id, :locales, null: false
      String      :value
    end

    create_table :pricing do
      foreign_key :id, :predicates, null: false
      foreign_key :locale_id, :locales, null: false

    end

    create_table :price_breaks do
      foreign_key :pricing_id, :pricing, null: false
      Integer     :argument, null: false
      check { argument >= 0 }
      Integer     :minimum, null: false
      index [:pricing_id, :argument, :minimum], unique: true
      Integer     :value, null: false
    end

    create_table :pricing_scopes do
      foreign_key :pricing_id, :pricing, null: false
      foreign_key :property_id, :properties, null: false
    end

    create_table :pricing_inputs do
      foreign_key :pricing_id, :pricing, null: false
      Integer     :argument
      check { argument >= 0 }
      foreign_key :variable_record_id, :variables, key: :record_id, null: false
    end

    create_table :instances do
      foreign_key :id, :predicates, null: false
      Integer     :quantity
      check { quantity >= 0 }
    end

    create_table :collections do
      foreign_key :id, :variables, null: false
    end

    create_table :collections_inherit do
      foreign_key :src_id, :collections, null: false
      foreign_key :dst_id, :collections, null: false
    end

  end
end