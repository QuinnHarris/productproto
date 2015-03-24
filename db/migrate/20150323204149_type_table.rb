Sequel.migration do
  change do
    create_table :variable_type_map do
      primary_key :id
      String      :name, null: false
      unique      [:name]
      String      :table, null: false
    end
  end
end
