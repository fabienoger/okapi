class Keyword < ActiveRecord::Base
  has_many :linked
  has_many :keyword_mark
end
