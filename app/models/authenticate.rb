class Authenticate < Sequel::Model
  model_map = {
      0 => :AuthenticateLogin,
      1 => :AuthenticateSystem
  }
  plugin :improved_class_table_inheritance, key: :type, model_map: model_map

  many_to_one :user
end

class AuthenticateLogin < Authenticate
  plugin :devise
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

end

class AuthenticateSystem < Authenticate

end