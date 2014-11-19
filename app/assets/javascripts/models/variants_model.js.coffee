Ink.Variant = DS.Model.extend
  quantity: DS.attr('number')
  properties: DS.hasMany('properties')
  product: DS.belongsTo('product')


Ink.Property = DS.Model.extend
  variants: DS.hasMany('variants')

Ink.Product = DS.Model.extend
  name: DS.attr('string')
  variants: DS.hasMany('variants')

window.Ink.ApplicationAdapter = DS.FixtureAdapter

Ink.Variant.reopenClass(FIXTURES: [
  { id: 1, quantity: 3, properties: [3, 9] }
])

Ink.Property.reopenClass(FIXTURES: [
  { id: 3 },
  { id: 9 }
])
