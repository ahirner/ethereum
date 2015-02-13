jQuery ->

  az = web3?

  debug = false

  get_campaigns = () ->
    campaigns_data = web3.db.getString('etherstarter', 'campaigns')
    if(campaigns_data == '')
      []
    else
      JSON.parse(campaigns_data)

  add_campaign = (campaign) ->
    campaigns = get_campaigns()
    campaigns.push(campaign)
    web3.db.putString('etherstarter', 'campaigns', JSON.stringify(campaigns))

  subscribe_whisper = () ->
    shh.watch(
      topic: [
        web3.fromAscii('etherstarter')
        web3.fromAscii(contract)
        web3.fromAscii('announce-campaign')
      ]
    ).arrived (msg) ->
      campaign = JSON.parse(web3.toAscii(msg.payload))
      #alert('WHISPER RECEIVED ' + response.description)
      add_campaign(campaign)
      #campaigns = web3.db.getString('etherstarter', 'campaigns')
      #alert(campaigns)

  post_whisper = (id, title, description) ->
    payload = web3.fromAscii(JSON.stringify({id: id, title: title, description: description}))
    shh.post
      topic: [
        web3.fromAscii('etherstarter')
        web3.fromAscii(contract)
        web3.fromAscii('announce-campaign')
      ]
      payload: payload
      ttl: 600

  if(az)
    shh = web3.shh
    contract = web3.db.get('etherstarter', 'contract')
    abi = JSON.parse(web3.db.getString('etherstarter', 'abi'))
    crowdfund = web3.eth.contract(contract, abi)
    subscribe_whisper()

  timeConverter = (UNIX_timestamp) ->
    a = new Date(UNIX_timestamp * 1000)
    months = [
      'Jan'
      'Feb'
      'Mar'
      'Apr'
      'May'
      'Jun'
      'Jul'
      'Aug'
      'Sep'
      'Oct'
      'Nov'
      'Dec'
    ]
    year = a.getFullYear()
    month = months[a.getMonth()]
    date = a.getDate()
    hour = a.getHours()
    min = a.getMinutes()
    sec = a.getSeconds()
    time = date + '. ' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec
    time

  current_campaign_id = () ->
    selector = $('select#campaigns').val()

  set_campaign_in_ui = (id) ->
    campaign = $.grep get_campaigns(), (e) ->
      return e.id == id
    campaign = campaign[0]

    $('.title h1').text(campaign.title)
    $('.description').text(campaign.description)

    recipient = crowdfund.call().get_recipient(id)

    # if recipient == 0

    if(az)
      goal = crowdfund.call().get_goal(id)
      deadline = crowdfund.call().get_deadline(id)
      raised = crowdfund.call().get_total(id)
      #alert(id)
      #alert(crowdfund.call().get_recipient(id))
      $('.raised .value span').text(raised)
      $('.total span').text(goal)

      $('.recipient_address span').text(crowdfund.call().get_recipient(id))
      percentage = (raised / goal) * 100
      $('.bar .inner').width("#{percentage}%")
      $('.info .percent').text("#{Math.round(percentage)}%")

      diff = deadline - Date.now() / 1000
      if diff > 0
        days_left = Math.round((diff) / (24*60*60))
        $('.info .time_left').text("#{days_left} days left")
      else
        $('.info .time_left').text("campaign ended")

      $('.notice span').text(timeConverter(deadline))


  $('.donate button').on 'click', (e) ->
    id = current_campaign_id()
    #alert('PLEDGING TO ' + id)
    amount = +$('.amount input').val()
    crowdfund.value(amount).contribute(id)
    #alert('SUCCESS')
    set_campaign_in_ui(id)
    raised = crowdfund.call().get_total(id)

    $('.raised .value span').text(raised)
    $('.amount input').val('')

    #alert("YOU PLEDGED " + amount + " WEI")


  if($('body.home').length > 0)

    # if(az)
    campaigns = get_campaigns()

    selector = $('select#campaigns')

    $.each campaigns, (index, campaign) ->
      if(index == 0)
        set_campaign_in_ui(campaign.id)

      selector.append($('<option/>', {
        value: campaign.id,
        text : campaign.title
      }))

    selector.on 'change', (e) ->
      selector = $('select#campaigns')
      id = selector.val()
      campaigns = get_campaigns()
      set_campaign_in_ui(id)


  # ADMIN

  if($('body.admin').length > 0)

    if(debug)
      $('#create_campaign').show()
      $('#title').val('Title')
      $('#description').val('Description')
      $('#goal').val('500')
      $('#duration').val('10')
      $('#recipient').val('dedc82cb364f93ddec1bf323069951b91c75c591')

    form = $('#create_campaign form')

    form.on 'submit', (e) ->
      e.preventDefault()

      title = form.find('#title').val()
      description = form.find('#description').val()
      goal = +form.find('#goal').val()
      deadline = (Date.now() / 1000) + +form.find('#duration').val()*24*60*60
      recipient = '0x' + form.find('#recipient').val()

      if(az)
        id = crowdfund.call().get_free_id()
        retval = crowdfund.transact().create_campaign(id, recipient, goal, deadline, 0, 0)
        post_whisper(id, title, description)

        $('#create_campaign').hide()
        $('#create_new_campaign').show()
        alert('CREATED')
        #alert(crowdfund.call().get_recipient(id))


    $('#create_campaign a#close').on 'click', (e) ->
      e.preventDefault()
      $('#create_campaign').hide()
      $('#create_new_campaign').show()

    $('#create_new_campaign').on 'click', (e) ->
      e.preventDefault()

      $(this).hide()
      $('#create_campaign').fadeIn()

      form.find('#title').focus()
