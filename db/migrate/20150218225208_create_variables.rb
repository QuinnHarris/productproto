Sequel.migration do
  change do

    create_table :locales do
      primary_key :id
      Integer     :type
      String      :name
    end

    create_table :locales_inherit do
      foreign_key :src_id, :locales, null: false
      foreign_key :dst_id, :locales, null: false
      primary_key [:src_id, :dst_id]
    end


    create_table :variables do
      primary_key :id
      Integer     :type, null: false
    end

    create_table :variables_inherit do
      foreign_key :src_id, :variables, null: false
      foreign_key :dst_id, :variables, null: false
      primary_key [:src_id, :dst_id]
    end

    create_table :predicates do
      primary_key :id
      foreign_key :variable_id, :variables, null: false
      TrueClass   :deleted, null: false, default: false
      DateTime    :created_at, null: false
    end

    create_table :predicates_and do
      foreign_key :variable_id, :variables, null: false
      foreign_key :predicate_id, :predicates, null: false
      primary_key [:variable_id, :predicate_id]
      index [:predicate_id, :variable_id], unique: true
    end

    create_table :value_naturals do
      foreign_key :id, :variables, null: false
      foreign_key :locale_id, :locales, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :locale_id, :created_at]
      String      :value, null: false
      column      :tsv, 'tsvector', null: false
    end
    #run 'CREATE INDEX value_naturals_tsearch ON value_naturals USING gin(tsv)'

    create_table :value_strings do
      foreign_key :id, :variables, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :created_at]
      String      :value, null: false
      index [:value]
    end

    create_table :value_floats do
      foreign_key :id, :variables, null: false
      foreign_key :unit_id, :locales, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :unit_id, :created_at]
      Float      :value, null: false
      index [:value]
    end

    create_table :value_integers do
      foreign_key :id, :variables, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :created_at]
      Integer     :value, null: false
    end

    create_table :price_singles do
      foreign_key :id, :variables, null: false
      foreign_key :locale_id, :locales, null: false
      primary_key [:id]
      DateTime    :created_at, null: false
      Integer     :value, null: false
    end

    create_table :prices do
      foreign_key :id, :variables, null: false
      foreign_key :locale_id, :locales, null: false
      primary_key [:id]
      DateTime    :created_at, null: false
    end

    create_table :price_discrete_breaks do
      foreign_key :price_id, :prices, null: false
      Integer     :argument, null: false
      check { argument >= 0 }
      Integer     :minimum, null: false
      DateTime    :created_at, null: false
      primary_key [:price_id, :argument, :minimum, :created_at]
      Integer     :value, null: false
    end

    create_table :price_scopes do
      foreign_key :price_id, :prices, null: false
      foreign_key :property_id, :variables, null: false
      primary_key [:price_id, :property_id]
    end

    create_table :price_inputs do
      foreign_key :price_id, :prices, null: false
      Integer     :argument, null: false
      check { argument >= 0 }
      foreign_key :variable_id, :variables, null: false
      primary_key [:price_id, :argument, :variable_id]
    end

  end
end