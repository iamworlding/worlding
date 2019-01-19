class ImportPoint < ApplicationRecord
    belongs_to :import
    has_many :import_photos, dependent: :destroy
    has_many :import_text_contents, dependent: :destroy
    has_many :import_thematic_points, dependent: :destroy
end
