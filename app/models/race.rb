class Race < ApplicationRecord
  has_many :horses, dependent: :destroy
  has_many :odds, dependent: :destroy
end
