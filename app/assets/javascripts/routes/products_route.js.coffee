Ink.ProductsRoute = Ember.Route.extend
  model: ->
    Ember.RSVP.hash
      instance: @store.find('instance', 2),
      variants: @store.find('variant')

  renderTemplate: (controller, model) ->
    @render 'products',
      controller: controller,
      model: product_data.data

    properties_controller = @controllerFor('properties')
    controller.set('propertiesController', properties_controller)
    @render 'properties',
      controller: properties_controller,
      outlet: 'properties',
      into: 'products',
      model: product_data.data.properties

    variants_controller = @controllerFor('variants')
    variants_controller.set('propertiesController', properties_controller)
    variants_controller.set('product_data', product_data)
    variants_controller.set('product_instance', model.instance)
    @render 'variants',
      controller: variants_controller,
      outlet: 'groups',
      into: 'products'


    @render 'decorations',
      outlet: 'decorations',
      into: 'products',
      model: product_data.data
