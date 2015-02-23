class SpamEmail < Sequel::Model(:sales__spam_emails)
  many_to_one :spam_batch
  many_to_one :business_email

  many_to_many :access_requests


  # Not secure, so what.
  ENCODE_KEY = ["eba69c93d88ef8fbc75a4787"].pack('H*')
  def self.hash_prefix(id_string)
    Digest::MD5.new.digest(id_string+ENCODE_KEY)[0..1]
  end

  def encode_ref_id
    id_string = [id].pack('L')
    Base64.urlsafe_encode64(id_string + self.class.hash_prefix(id_string))
  end

  def self.decode_ref_id(string)
    return nil unless string.length == 8
    result = Base64.urlsafe_decode64(string)
    id_string = result[0..3]
    return nil unless result[4..5] == hash_prefix(id_string)
    id_string.unpack('L').first
  end

  def self.find_by_ref_id(string)
    id = decode_ref_id(string)
    return unless id
    self[id]
  end
end
