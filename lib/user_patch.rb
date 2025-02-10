module ResumenActividadesUserPatch
  def self.included(base)
    base.class_eval do
      has_many :time_entries, class_name: 'TimeEntry', foreign_key: 'user_id' unless reflect_on_association(:time_entries)
    end
  end
end
