# -*- encoding : utf-8 -*-
require 'sequel'

class RegisterConfirm < Sequel::Model
  many_to_one :user

  HASH_SALT_LEN = 10

  def self.generate_hash(length = HASH_SALT_LEN)
    length = length.to_i
    raise 'Invalid salt length!' if length < 0
    salt = (1..length*2).map{rand(16).to_s(16)}.join
    Digest::SHA2.hexdigest(salt + '---' + Time.now.to_s)
  end

  def self.register(user)
    user_hash = generate_hash
    begin
      register_confirm = create(:user_hash => user_hash,
                                :user_id => user.id,
                                :time => Time.now)
      return register_confirm
    rescue => e
      Ramaze::Log.error(e)
    end
    return nil
  end

end
