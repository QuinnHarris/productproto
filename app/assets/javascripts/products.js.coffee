head_select = (li) ->
  $(li).addClass('selected').siblings().removeClass('selected')

row_sum = (tr) ->
  quantity = 0
  for inp in $('td input', tr)
    quantity += parseInt(inp.value) || 0
  quantity

row_calc = (tr) ->
  qty = row_sum(tr)
  $('.quantity', tr).text(qty)
  price = parseFloat($('.unit_price', tr).text())
  $('.total_price', tr).text(price * qty)
  cost = parseFloat($('.unit_cost', tr).text())
  $('.total_cost', tr).text(cost * qty)
  $('.profit', tr).text((price - cost) * qty)

$ ->
  $('dl#properties li').click ->
    head_select this
    $('tbody.current').data('property', $(this).data('property'))
    td = $('tbody.current div.swatch')
    td.empty()
    $('a *', this).clone().appendTo(td)

  collapse = (tbody) ->
    tbody.removeClass('current').removeClass('ready')
    for tr in $('tr:not(.head)', tbody)
      if row_sum(tr) == 0
        $(tr).addClass('shrink')

  expand = (tbody) ->
    tbody.addClass('current')
    $('tr', tbody).removeClass('shrink')

  $('table.prices')
  .on 'change', 'tr td input', ->
    row_calc $(this).parents('tr')

  .on 'click', 'tbody', ->
    if $(this).is('.current')
      return
    collapse $('table.prices tbody.current')
    expand $(this)
    prop = $(this).data('property')
    head_select $('dl#properties li[data-property="'+prop+'"]')

  .on 'click', 'a.remove', ->
    tbody = $(this).parents('tbody')
    prop = tbody.data('property')
    tbody.remove()
    $('dl#properties li[data-property="'+prop+'"]').removeClass('included')
    expand $('table.prices tbody:first-child')

  .on 'transitionend', 'tr', ->
    tbody = $(this).parent()
    if tbody.hasClass('current')
      tbody.addClass('ready')



  $('a.add').click ->
    prev = $('table.prices tbody.current')
    next = prev.clone()
    for inp in $('td input', next)
      inp.value = ''
    for tr in $('tr', next)
      row_calc tr
    $('dl#properties li.selected').addClass('included')
    collapse prev
    next.appendTo($('table.prices'))
    head_select $('dl#properties li:first-child')
