jQuery ->

  $('.admin #create_campaign form').on 'submit', (e) ->
    e.preventDefault()

  $('.admin #create_campaign a#close').on 'click', (e) ->
    e.preventDefault()
    $(this).parents('#create_campaign').hide()
    $('.admin #create_new_campaign').show()

  $('.admin #create_new_campaign').on 'click', (e) ->
    e.preventDefault()

    form = $('#create_campaign form')

    $(this).hide()
    $('#create_campaign').fadeIn()

    form.find('input#title').focus()
