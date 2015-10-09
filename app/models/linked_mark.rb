class LinkedMark < ActiveRecord::Base
  belongs_to :user
  belongs_to :linked
end
