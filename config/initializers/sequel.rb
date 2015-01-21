module Sequel::Plugins::FactoryGirlSupport
  module InstanceMethods
    def save!
      save_changes raise_on_save_failure: true
    end
  end
end

# Sequel Config
# Allowed options: :sql, :ruby.
# Dump in SQL to capture stored proceedures and triggers
Rails.application.config.sequel.schema_format = :sql

# Whether to dump the schema after successful migrations.
# Defaults to false in production and test, true otherwise.
#config.sequel.schema_dump = true

# These override corresponding settings from the database config.
#config.sequel.max_connections = 16
#config.sequel.search_path = %w(mine public)

# Configure whether database's rake tasks will be loaded or not
# Defaults to true
#config.sequel.load_database_tasks = false

Sequel::Model.db.extension :pg_array, :pg_inet, :pg_hstore
Sequel.extension :pg_array_ops, :pg_hstore_ops
Sequel::Model.plugin :active_model
Sequel::Model.plugin :timestamps
Sequel::Model.plugin :factory_girl_support

