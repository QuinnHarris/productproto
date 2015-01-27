class SpamMailer < ApplicationMailer
  def initialize(method_name, version, email, *args)
    @version = version
    @email_record = email
    super method_name, *args
  end
  attr_reader :version, :versions, :email_record

  def set_versions(versions)
    if @versions
      raise "Versions mismatch" if @versions != versions
    else
      @versions = versions
    end
  end
  def choose(*args)
    list = args.flatten
    set_versions(list.length)
    list[version]
  end
  helper_method :version, :set_versions, :choose


  def url_options
    return super unless @email_record
    super.merge(r: @email_record.encode_ref_id)
  end

  def self.always_emails
    BusinessEmail.where(type: 'Always').eager(:business).all
  end

  def self.always_spam_email
    be = BusinessEmail.where(type: 'Always').eager(:business).first
    be.spam_emails_dataset.first
  end

  def self.annoy(method_name, count, from_iteration = nil)
    raise "Method not implemented" unless action_methods.include?(method_name.to_s)

    sb_ds = SpamBatch.where(name: method_name.to_s)
    sb_ds = sb_ds.where { |o| o.iteration >= from_iteration } if from_iteration
    sb_last = sb_ds.order(:iteration).reverse.first
    iteration = [sb_last ? sb_last.iteration+1 : 0, from_iteration].compact.max

    se_ds = sb_ds.join(:spam_emails, :spam_batch_id => :id).select(:spam_emails__business_email_id)

    # Very slow could use something like http://stackoverflow.com/questions/8674718/best-way-to-select-random-rows-postgresql
    be_part = BusinessEmail.select_append(
        Sequel.function(:rank).over(partition: :business_id, order: :id),
        Sequel.function(:random) )
    be_records = BusinessEmail.from(be_part).where(id: se_ds).invert.order(:rank, :random).first(count)
    be_records = always_emails + be_records

    raise "No Records" if be_records.empty?

    this_sb = SpamBatch.create(name: method_name.to_s, iteration: iteration)

    #yaml_path = send(:new).lookup_context.find(name, [mailer_name], nil, [], formats: ['yaml'])

    versions = nil
    version = 0
    be_records.each do |be|
      SpamEmail.db.transaction do
        se = SpamEmail.create(spam_batch: this_sb, business_email: be, version: version) unless be.new?

        mailer = self.send(:new, method_name, version, se)
        if versions
          raise "Version mismatch" unless versions == mailer.versions
        else
          versions = mailer.versions
          raise "Must have versions" unless versions
        end

        version += 1
        version = 0 if version >= versions
      end
    end
  end

  default from: 'info@ornimo.com',
          to: Proc.new { @email_record.business_email.value }

  def introduction
    set_versions 2
    mail(subject: "This is #{choose('that', 'this')}")
  end
end
