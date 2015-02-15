jQuery ->

  debug = false

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

  subscribe_to_whispers = () ->
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

  shh = web3.shh
  contract = web3.db.get('etherstarter', 'contract')
  abi = JSON.parse(web3.db.getString('etherstarter', 'abi'))
  crowdfund = web3.eth.contract(contract, abi)
  subscribe_to_whispers()

  # HOME

  if($('body.home').length > 0)

    get_selector = () ->
      $('select#campaigns')

    current_campaign_id = () ->
      get_selector().val()

    show_campaign = (id) ->
      campaign = $.grep get_campaigns(), (e) ->
        e.id == id
      campaign = campaign[0]

      get_selector().val(id)

      $('.title h1').text(campaign.title)
      $('.description .inner').text(campaign.description)
      $('.description').show()

      recipient = crowdfund.call().get_recipient(id)

      $('.pledge').show()
      $('.campaign').show()

      # if recipient == 0

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

    $('.pledge button').on 'click', (e) ->
      id = current_campaign_id()
      #alert('PLEDGING TO ' + id)
      amount = +$('.amount input').val()
      crowdfund.value(amount).contribute(id)
      #alert('SUCCESS')
      show_campaign(id)
      raised = crowdfund.call().get_total(id)

      $('.raised .value span').text(raised)
      $('.amount input').val('')

      #alert("YOU PLEDGED " + amount + " WEI")

    campaigns = get_campaigns()

    $.each campaigns, (index, campaign) ->
      if(index == 0)
        show_campaign(campaign.id)

      get_selector().append($('<option/>', {
        value: campaign.id,
        text : campaign.title
      }))

    get_selector().on 'change', (e) ->
      show_campaign(current_campaign_id())

    id = Url.queryString("campaign_id")
    if id
      show_campaign(id)

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

      id = crowdfund.call().get_free_id()
      retval = crowdfund.transact().create_campaign(id, recipient, goal, deadline, 0, 0)
      post_whisper(id, title, description)

      form.find('input[type=text], textarea').val('')

      if Url.queryString("create") != '1'
        $('#create_campaign').hide()
        $('#create_new_campaign').show()

      #window.location.href = "etherstarter.html?campaign_id=#{id}"
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
