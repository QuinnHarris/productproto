# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Variable.update_types
User.db.alter_table(:assertions) { set_column_allow_null :created_user_id }
locale = Locale.create(name: 'system')
user = User.create(value: 'system', locale: locale)
user.created_user_id = user.id
user.save
User.db.alter_table(:assertions) { set_column_not_null :created_user_id }
