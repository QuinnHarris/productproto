Ink.Variant = DS.Model.extend
  quantity: DS.attr('number')
  #properties: DS.hasMany('properties')
  instance: DS.belongsTo('instance')
  #product: DS.belongsTo('product')
  property_ids: DS.attr() # Array of Ids
  #property_ids: Em.computed 'properties', ->
  #  @get('properties').map (p) -> parseInt(p.get('id'))

#Ink.Property = DS.Model.extend
#  variants: DS.hasMany('variants')

Ink.Instance = DS.Model.extend
  variants: DS.hasMany('variants')

#Ink.Product = DS.Model.extend
#  name: DS.attr('string')
#  variants: DS.hasMany('variants')

Ink.ApplicationAdapter = DS.FixtureAdapter

Ink.Variant.reopenClass(FIXTURES: [
  { id: 1, instance: 2, quantity: 3, property_ids: [3, 9] }
  { id: 2, instance: 2, quantity: 2, property_ids: [4, 9] }
  { id: 3, instance: 2, quantity: 1, property_ids: [5, 9] }
])

#Ink.Property.reopenClass(FIXTURES: ({ id: i } for i in [1..100] ) )

Ink.Instance.reopenClass(FIXTURES: [
  { id: 2, variants: [1, 2, 3] }
])