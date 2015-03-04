class Locale < Sequel::Model
  plugin :single_table_inheritance, :type,
         model_map: {
             0 => :Locale,
             1 => :Unit,
             2 => :Currency,
             3 => :Language
         }

  many_to_many :predecessors, class: Locale, reciprocal: :successors,
               join_table: :locales_inherit,
               left_key: :successor_id, right_key: :predecessor_id

  many_to_many :successors, class: Locale, reciprocal: :predecessors,
               join_table: :locales_inherit,
               left_key: :successor_id, right_key: :predecessor_id

  one_to_many :users
end

class Unit < Locale

end

class Currency < Locale

end

class Language < Locale

end