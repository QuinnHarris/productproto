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

# PG streaming
Sequel::Model.db.extension :pg_streaming
# Sequel::Model.db.stream_all_queries = true

module SequelRails
  class Migrations
    class << self
      alias_method :dump_schema_information_orig, :dump_schema_information

      def dump_schema_information(opts = {})
        if opts.fetch :sql
          "SET search_path = public, pg_catalog;\n"
        else
          ''
        end + dump_schema_information_orig(opts)
      end
    end
  end
end