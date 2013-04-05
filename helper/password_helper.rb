
class PasswordHelper

  PASSWORD_SALT_LEN = 4

  # length - in bytes
  def self.generate_salt(length = PASSWORD_SALT_LEN)
    length = length.to_i
    raise 'Invalid salt length!' if length < 0
    salt = (1..length*2).map{rand(16).to_s(16)}.join
    return salt
  end

  def self.encrypt_password(password, salt = generate_salt())
    salt + '$' + Digest::SHA2.hexdigest(salt + '---' + password)
  end

  def self.check_password?(given_password, valid_encrypted_password)
    salt = valid_encrypted_password.split('$')[0]
    encrypted_password = encrypt_password(given_password, salt)
    encrypted_password == valid_encrypted_password
  end
end