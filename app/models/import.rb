class Import < ApplicationRecord
    has_many :import_points, dependent: :destroy
end
