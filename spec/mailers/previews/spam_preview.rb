class SpamPreview < ActionMailer::Preview
  # Override emails to read template files instead of instance methods
  def self.emails
    Dir["#{Rails.root}/app/views/spam_mailer/*.erb"].map do |s|
      name = File.basename(s).split('.').first
      versions = SpamMailer.send(:new, name, 0, SpamMailer.always_email).versions
      (0...versions).map { |v| "#{name}-#{v}"}
    end.flatten
  end

  def method_missing(method, *args)
    return super unless self.class.email_exists?(method.to_s)
    method_name, version = method.to_s.split('-')
    SpamMailer.send(method_name, Integer(version), SpamMailer.always_email)
  end
end
