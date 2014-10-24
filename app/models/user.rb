class User < Sequel::Model
  plugin :devise
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  one_to_many :products
  one_to_many :bids
end
