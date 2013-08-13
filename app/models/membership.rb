class Membership < ActiveRecord::Base
  belongs_to :member, dependent: :destroy
  validates_presence_of :member_id, unique: true
end
