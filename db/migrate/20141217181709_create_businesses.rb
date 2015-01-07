Sequel.migration do 
  change do

    create_table :businesses do
      primary_key :id
      String      :name, null: false
      String      :website
    end

    create_table :business_phones do
      primary_key :id
      foreign_key :business_id, :businesses, null: false
      String      :source
      String      :type
      String      :value, null: false
      Bignum      :number, null: false
    end

    create_table :business_emails do
      primary_key :id
      foreign_key :business_id, :businesses, null: false
      String      :source
      String      :type
      String      :value, null: false
    end

    create_table :business_addresses do
      primary_key :id
      foreign_key :business_id, :businesses, null: false
      String      :source
      String      :type
      String      :address1
      String      :address2
      String      :value
      String      :city
      String      :state
      String      :postalcode
      String      :country
    end

    create_table :sources do
      primary_key :id
      String      :name, null: false
      String      :url
    end

    create_table :business_sources do
      foreign_key :business_id, :businesses, null: false
      foreign_key :source_id, :sources, null: false
      primary_key [:business_id, :source_id]
      String      :reference
    end
  end
end