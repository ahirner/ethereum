jQuery ->

  debug = true

  web3 = require('web3')
  web3.setProvider(new web3.providers.HttpSyncProvider('http://localhost:3000/client'))

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

  reconstruct_identity = (lsb, msb) ->
    shh_identity = "0x" + msb.times(new BigNumber(2).toPower(256)).plus(lsb).toString(16)

  get_campaign_identity = (id) ->
    lsb = crowdfund.call().get_identity(id)[0]
    msb = crowdfund.call().get_identity(id)[1]
    reconstruct_identity(lsb, msb);

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

      if (msg.from == get_campaign_identity (campaign.id))
        add_campaign(campaign)


  post_whisper = (id, shh_identity, title, description) ->
    payload = web3.fromAscii(JSON.stringify({id: id, title: title, description: description}))
    shh.post
      topic: [
        web3.fromAscii('etherstarter')
        web3.fromAscii(contract)
        web3.fromAscii('announce-campaign')
      ]
      from: shh_identity
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
      percentage = Math.min(100, (raised / goal) * 100)
      $('.bar .inner').width("#{percentage}%")
      $('.info .percent').text("#{Math.floor(percentage)}%")

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
      shh_identity = web3.shh.newIdentity()

      shh_identity_n = new BigNumber(shh_identity.substring(2), 16)
      lsb = shh_identity_n.modulo(new BigNumber(2).toPower(256))
      msb = shh_identity_n.minus(lsb).dividedBy(new BigNumber(2).toPower(256))

      id = crowdfund.call().get_free_id()
      retval = crowdfund.transact().create_campaign(id, recipient, goal, deadline, lsb, msb)
      post_whisper(id, shh_identity, title, description)
      form.find('input[type=text], textarea').val('')

      if Url.queryString("create") != '1'
        $('#create_campaign').hide()
        $('#create_new_campaign').show()

      window.location.href = "/?campaign_id=#{id}"
      #alert('CREATED')
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
