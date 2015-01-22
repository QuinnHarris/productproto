Sequel.migration do
  # CREATE EXTENSION hstore
  up { create_schema :access }
  down { drop_schema :access }

  up do

  end

  change do
    create_table :access__sessions do
      primary_key :id
      String      :user_agent
      String      :language
      DateTime    :created_at, null: false
    end

    create_table :access__requests do
      primary_key :id
      foreign_key :session_id, :access__sessions, null: false
      String      :host
      String      :controller
      String      :action
      Integer     :action_id
      column      :params, :hstore
      String      :referer
      column      :address, :inet
      DateTime    :created_at, null: false
      Boolean     :secure
    end


    create_table :spam_batches do
      primary_key :id
      String      :name, null: false
      Integer     :iteration, null: false
      DateTime    :created_at, null: false
    end

    create_table :spam_emails do
      primary_key :id
      foreign_key :spam_batch_id, :spam_batches, null: false
      foreign_key :business_email_id, :business_emails, null: false
      unique      [:spam_batch_id, :business_email_id]
      Integer     :version, null: false
      String      :status
      DateTime    :created_at, null: false
    end

    create_table :spam_email_requests do
      foreign_key :spam_email_id, :spam_emails, null: false
      foreign_key :access_request_id, :access__requests, null: false, unique: true
    end
  end
end