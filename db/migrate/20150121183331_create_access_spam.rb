Sequel.migration do
  # CREATE EXTENSION hstore

  sales_tables = %w(businesses business_phones business_emails business_addresses sources business_sources)

  up do
    create_schema :access
    create_schema :sales

    sales_tables.each { |t| run "ALTER TABLE #{t} SET SCHEMA sales" }

    #sb = SpamBatch.create(name: 'initial', iteration: 0)
    #b = Business.create(name: 'ZenDecorator', website: 'http://www.zendecorator.com')
    #be = BusinessEmail.create(business: b, type: 'Always', value: 'quinn@zendecorator.com')
    #se = SpamEmail.create(spam_batch: sb, business_email: be, version: 0)

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


    create_table :sales__spam_batches do
      primary_key :id
      String      :name, null: false
      Integer     :iteration, null: false
      DateTime    :created_at, null: false
    end

    create_table :sales__spam_emails do
      primary_key :id
      foreign_key :spam_batch_id, :sales__spam_batches, null: false
      foreign_key :business_email_id, :sales__business_emails, null: false
      unique      [:spam_batch_id, :business_email_id]
      Integer     :version, null: false
      String      :status
      DateTime    :created_at, null: false
    end

    create_table :sales__access_requests_spam_emails do
      foreign_key :spam_email_id, :sales__spam_emails, null: false
      foreign_key :access_request_id, :access__requests, null: false, unique: true
    end

    create_table :sales__given_emails do
      primary_key :id
      foreign_key :access_request_id, :access__requests, null: false
      String      :value, null: false
    end
  end

  down do
    %i(sales__given_emails sales__access_requests_spam_emails sales__spam_emails sales__spam_batches access__requests access__sessions).each do |table|
      drop_table table
    end

    sales_tables.each { |t| run "ALTER TABLE sales.#{t} SET SCHEMA public" }

    drop_schema :sales
    drop_schema :access
  end
end