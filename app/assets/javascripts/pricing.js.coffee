Array.prototype.isEqual = (b) ->
  return true if @ == b
  return false if @.length != b.length

  for e, i in @
    return false unless Em.isEqual(e, b[i])
  true

class window.PricingBase
  constructor: (@data) ->
    @properties_map = []
    for prop in @data.properties
      map = new Ember.Map()
      for l in prop.list
        map.set(l.id, l)
      @properties_map.push(map)

  _selectStack: (list, preds) ->
    list.filter((elem) ->
      Em.makeArray(elem.predicate).every (set) ->
        Em.makeArray(set).find (e) -> preds.contains(e)
    ).sortBy('priority')

  _costStack: (predicate) -> @_selectStack(@data.costs, predicate)
  _priceStack: (predicate) -> @_selectStack(@data.costs.concat(@data.prices), predicate)

  variantGroups: (predicate) ->
    list = Em.copy(@data.variant_group.list)
    result = []
    until Em.isEmpty(list)
      stack = @_priceStack(predicate.concat(list[0].id))
      sub_list = [list.shift()]
      until Em.isEmpty(list) ||
            !Em.isEqual(stack, @_priceStack(predicate.concat(list[0].id)))
        sub_list.push(list.shift())
      result.push(sub_list)
    return result

  propertyFromPredicate: (predicate) ->
    for prop in @properties_map
      predicate.find (p) -> prop.has(p)


  _combineBreaks: (meta_list, func) ->
    meta_list = (Em.copy(l) for l in meta_list)

    min = meta_list.reduce(((m, l) -> Math.max(m, l[0].n)), 0)

    qtys = []
    for m in meta_list
      for l in m
        qtys.push l.n if l.n >= min

    for qty in qtys.uniq()
      for list in meta_list
        list.shift() if list[1] && list[1].n == qty

      { n: qty, v: func.apply(this, (l[0].v for l in meta_list)) }

  _applyStack: (list, predicate, cost_basis_list = [], axis_list = []) ->
    stack = @_selectStack(list, predicate)

    # Find unique input mult combinations
    for entry in stack
      elem = [entry.input, (entry.mult ? [0])]
      unless axis_list.find((e) -> Em.isEqual(e, elem))
        axis_list.push(elem)

    basis = for e in axis_list
      input = e[0]
      mult = e[1]
      elem = cost_basis_list.find((cb) -> Em.isEqual(cb.input, input) && Em.isEqual(cb.mult, mult))
      cost_basis = elem.breaks if elem
      cost_basis ?= []
      basis = cost_basis
      for elem in stack.filter((e) -> Em.isEqual(e.input, input) && Em.isEqual(e.mult ? [0], mult))
        meta_list = [basis, elem.breaks, cost_basis].compact()
        basis = switch elem.op
          when 'add'
            @_combineBreaks meta_list, (a, b) -> a + b
          when 'mult'
            @_combineBreaks meta_list, (a, b) -> a * b
          when 'disc'
            @_combineBreaks meta_list, ((a, b, c) -> (a - c)*b + c)
          else
            elem.breaks
      { input: input, mult: mult, breaks: basis }

    { basis: basis, axis: axis_list }

  getCostPrice: (predicate) ->
    costs = @_applyStack(@data.costs, predicate)
    prices = @_applyStack(@data.prices, predicate, costs.basis, costs.axis)
    axis = prices.axis.map((e) -> { input: e[0], mult: e[1] })
    { costs: costs.basis, prices: prices.basis, axis: axis }

  getPrice: (basis, quantity_list) ->
    sum = 0
    for base in basis
      quantity = quantity_list[base.input]
      quantity = 1 unless quantity
      result = null
      for br in base.breaks
        break if br.n > quantity
        result = br.v
      sum += result if result
    sum

