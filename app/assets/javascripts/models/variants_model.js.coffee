Ink.Variant = DS.Model.extend
  quantity: DS.attr('number', async: true)
  properties: DS.hasMany('properties', async: true)
  instance: DS.belongsTo('instance', async: true)
  #product: DS.belongsTo('product')

Ink.Property = DS.Model.extend
  variants: DS.hasMany('variants', async: true)

Ink.Instance = DS.Model.extend
  variants: DS.hasMany('variants', async: true)

#Ink.Product = DS.Model.extend
#  name: DS.attr('string')
#  variants: DS.hasMany('variants')

Ink.ApplicationAdapter = DS.FixtureAdapter

Ink.Variant.reopenClass(FIXTURES: [
  { id: 1, instance: 1, quantity: 3, properties: [3, 9] }
])

Ink.Property.reopenClass(FIXTURES: [
  { id: 3 },
  { id: 9 }
])

Ink.Instance.reopenClass(FIXTURES: [
  { id: 1, variants: [1] }
])