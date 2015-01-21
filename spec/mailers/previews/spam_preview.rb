class SpamPreview < ActionMailer::Preview
  # Override emails to read template files instead of instance methods
  def self.emails
    Dir["#{Rails.root}/app/views/spam_mailer/*.erb"].map do |s|
      File.basename(s).split('.').first
    end
  end

  def method_missing(method, *args)
    return super unless self.class.email_exists?(method.to_s)
    SpamMailer.send(method)
  end
end
