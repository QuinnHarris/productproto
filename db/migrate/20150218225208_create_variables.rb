Sequel.migration do
  change do

    create_table :locales do
      primary_key :id
      Integer     :type, null: false
      String      :name
    end

    create_table :locales_inherit do
      foreign_key :predecessor_id, :locales, null: false
      foreign_key :successor_id, :locales, null: false
      primary_key [:predecessor_id, :successor_id]
    end


    create_table :variables do
      primary_key :id
      Integer     :type, null: false
    end

    create_table :assertions do
      foreign_key :id, :variables, null: false
      primary_key [:id]

      String      :value
      DateTime    :created_at, null: false
    end

    create_table :users do
      foreign_key :id, :assertions, null: false
      primary_key [:id]

      foreign_key :locale_id, :locales, null: false
    end
    alter_table :assertions do
      add_foreign_key :created_user_id, :users, null: false # Change later
    end

    create_table :assertion_relations do
      foreign_key :predecessor_id, :assertions, null: false
      foreign_key :successor_id, :assertions, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:predecessor_id, :successor_id, :created_at]
      TrueClass   :deleted, null: false, default: false

      DateTime    :version_lock
      Integer     :access, default: 2147483647
    end

    # # array_agg might work in 9.5 https://wiki.postgresql.org/wiki/Todo
    # run %(
    #   CREATE AGGREGATE array_aggcat (anyarray)
    #   (   sfunc = array_cat,
    #       stype = anyarray,
    #       initcond = '{}'
    #   );
    # )
    #
    # # Use stored procedure and trigger to test for cycles
    # # This will not detect cycles when two transactions are opened
    # # simultaneously that together insert rows causing a cycle
    # run %(
    #   CREATE FUNCTION cycle_test() RETURNS TRIGGER AS $$
    #   DECLARE
    #     cycle_path integer ARRAY;
    #   BEGIN
    #     IF (TG_OP = 'UPDATE' AND
    #         NEW.successor_id = OLD.successor_id AND
    #         NEW.predecessor_id = OLD.predecessor_id) THEN
    #       RETURN NULL;
    #     END IF;
    #
    #     WITH RECURSIVE assertion_decend AS (
    #         SELECT NEW.successor_id AS id,
    #                ARRAY[NEW.predecessor_id, NEW.successor_id] AS path,
    #                false AS cycle
    #       UNION
    #         SELECT assertion_relations.successor_id,
    #                assertion_decend.path || assertion_relations.successor_id,
    #          assertion_relations.successor_id = ANY(assertion_decend.path)
    #           FROM assertion_relations
    #       INNER JOIN assertion_decend
    #         ON assertion_relations.predecessor_id = assertion_decend.id
    #           WHERE NOT assertion_decend.cycle
    #     ) SELECT path INTO cycle_path
    #         FROM assertion_decend WHERE cycle LIMIT 1;
    #
    #     IF FOUND THEN
    #       RAISE EXCEPTION 'cycle found %', cycle_path;
    #     END IF;
    #
    #     RETURN NULL;
    #   END
    #   $$ LANGUAGE plpgsql;
    #
    #   CREATE CONSTRAINT TRIGGER cycle_test
    #     AFTER INSERT OR UPDATE ON assertion_relations
    #     FOR EACH ROW EXECUTE PROCEDURE cycle_test();
    # )

    create_table :authenticates do
      primary_key :id
      foreign_key :user_id, :users, null: false
      Integer     :type
    end

    create_table :authenticate_logins do
      foreign_key :id, :authenticates, null: false
      primary_key [:id]

      ## Database authenticatable
      String   :email,              null: false, default: ""
      index    :email,              unique: true
      String   :encrypted_password, null: false, default: ""

      ## Recoverable
      String   :reset_password_token
      index    :reset_password_token, unique: true
      DateTime :reset_password_sent_at

      ## Rememberable
      DateTime :remember_created_at

      ## Trackable
      Integer  :sign_in_count, default: 0, null: false
      DateTime :current_sign_in_at
      DateTime :last_sign_in_at
      column   :current_sign_in_ip, :inet
      column   :last_sign_in_ip, :inet

      ## Confirmable
      String   :confirmation_token
      index    :confirmation_token,     unique: true
      DateTime :confirmed_at
      DateTime :confirmation_sent_at
      String   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      Integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      String   :unlock_token # Only if unlock strategy is :email or :both
      index    :unlock_token,           unique: true
      DateTime :locked_at

      ## OmniAuth
      String   :provider
      String   :uid
      String   :name

      DateTime    :created_at,  null: false
      DateTime    :updated_at
    end

    create_table :authenticate_systems do
      foreign_key :id, :authenticates, null: false
      primary_key [:id]

      String      :host, null: false
      String      :username, null: false
    end

    create_table :namespaces do
      primary_key :id
      String      :name, null: false
    end

    # Does a property need to be a predicate variable?  If not can drop values table.
    create_table :properties do
      foreign_key :id, :variables, null: false
      foreign_key :locale_id, :locales, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :locale_id, :created_at]
      String      :value, null: false
      #column      :tsv, 'tsvector', null: false
    end

    create_table :namespaces_properties do
      foreign_key :namespace_id, :namespaces, null: false
      foreign_key :property_id, :variables, null: false
    end

    create_table :values do
      foreign_key :id, :variables, null: false
      primary_key [:id]
      foreign_key :property_id, :variables, null: false
      unique [:id, :property_id]
    end

    create_table :predicates do
      primary_key :id
      foreign_key :value_id, :values, null: false
      column      :assertion_dependent_ids, 'integer[]', null: false
      column      :value_dependent_ids, 'integer[]', null: false
      TrueClass   :deleted, null: false, default: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      index :assertion_dependent_ids, type: :gin
    end

    create_table :value_naturals do
      foreign_key :id, :values, null: false
      foreign_key :locale_id, :locales, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :locale_id, :created_at]
      String      :value, null: false
      #column      :tsv, 'tsvector', null: false
    end
    #run 'CREATE INDEX value_naturals_tsearch ON value_naturals USING gin(tsv)'

    create_table :value_strings do
      foreign_key :id, :values, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :created_at]
      String      :value, null: false
      index [:value]
    end

    create_table :value_floats do
      foreign_key :id, :values, null: false
      foreign_key :unit_id, :locales, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :unit_id, :created_at]
      Float      :value, null: false
      index [:value]
    end

    create_table :value_integers do
      foreign_key :id, :values, null: false
      foreign_key :unit_id, :locales, null: true
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :created_at]
      Integer     :value, null: false
    end

    create_table :value_booleans do
      foreign_key :id, :values, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:id, :created_at]
      Boolean     :value, null: false
    end


    create_table :functions do
      foreign_key :id, :values, null: false
      foreign_key :locale_id, :locales, null: false
      primary_key [:id]
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
    end

    create_table :function_discrete_breaks do
      foreign_key :function_id, :functions, null: false
      Integer     :argument, null: false
      check { argument >= 0 }
      Integer     :minimum, null: false
      foreign_key :created_user_id, :users, null: false
      DateTime    :created_at, null: false
      primary_key [:function_id, :argument, :minimum, :created_at]
      Integer     :value, null: false
    end

    create_table :function_scopes do
      foreign_key :function_id, :functions, null: false
      foreign_key :property_id, :variables, null: false
      primary_key [:function_id, :property_id]
    end

    create_table :function_inputs do
      foreign_key :function_id, :functions, null: false
      Integer     :argument, null: false
      check { argument >= 0 }
      foreign_key :variable_id, :variables, null: false
      primary_key [:function_id, :argument, :variable_id]
    end

  end
end