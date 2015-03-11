class AssertionRelation < Sequel::Model
  many_to_one :successor, class: :Assertion
  many_to_one :predecessor, class: :Assertion

  many_to_one :created_user, class: :User
  plugin :context, created_user: :user

  def self.decend_dataset(basis, filter = 2147483647)
    base_ds = Variable.dataset.where(id: basis)
    base_ds = base_ds.select_append(Sequel.as(filter, :access),
                          Sequel.as(0, :depth))

    cte_table = :assert_decend

    r_ds = db.from(cte_table).join(table_name, :successor_id => :id)

    r_ds = r_ds.join(Variable.table_name, :id => :predecessor_id)

    r_ds = r_ds.select(
                   Sequel.qualify(Variable.table_name, :id),
                   Sequel.qualify(Variable.table_name, :type),
                   (Sequel.qualify(cte_table, :access).sql_number &
                       Sequel.qualify(table_name, :access)).as(:access),
                   Sequel.+(:depth, 1).as(:depth) )

    db.from(cte_table).with_recursive(cte_table, base_ds, r_ds, union_all: false)
  end
end

class Assertion < Variable
  set_context_map created_user: :user

  one_to_many :predecessor_relations, class: AssertionRelation, reciprocal: :successor
  one_to_many :successor_relations, class: AssertionRelation, reciprocal: :predecessor

  many_to_many :predecessors, class: Assertion, join_table: :assertion_relations, reciprocal: :successor, left_key: :successor_id
  many_to_many :successors, class: Assertion, join_table: :assertion_relations, reciprocal: :predecessor, left_key: :predecessor_id
end

class ProductClass < Assertion

end

class Collection < Assertion

end

class Supplier < Assertion

end

class InstanceCollection < Collection

end

class Product < Collection

end
