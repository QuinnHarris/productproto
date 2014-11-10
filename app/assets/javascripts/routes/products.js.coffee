Ink.ProductsRoute = Ember.Route.extend
  model: ->
    product_data.data

  renderTemplate: ->
    @render 'products'
    @render 'variantGroups', outlet: 'groups', into: 'products'
