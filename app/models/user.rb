class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :send_messages, class_name: 'Message', foreign_key: 'sender_user_id'
  has_many :receiver_messages, class_name: 'Message', foreign_key: 'receiver_user_id'
  has_many :procedures
  has_many :notifications
  belongs_to :local_prosecution, optional: true
  belongs_to :police_unit, optional: true
  validates :rut, presence: true, rut: true
end

