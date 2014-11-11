Ink.ProductsRoute = Ember.Route.extend
  model: ->
    product_data.data

  renderTemplate: (controller, model) ->
    @render 'products',
      controller: controller,
      model: model

    properties_controller = this.controllerFor('properties')
    controller.set('propertiesController', properties_controller)
    @render 'properties',
      controller: properties_controller,
      outlet: 'properties',
      into: 'products',
      model: model.properties

    @render 'variantGroups',
      outlet: 'groups',
      into: 'products'

