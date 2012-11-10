#global FB

$cr = window.$cr = window.$cr or {}

process_login = (res) ->
  if res.status != 'connected'
    $('.login-status').removeClass('in').addClass('out')
  else
    $('.login-status').addClass('in').removeClass('out')
    FB.api '/me', (res) ->
      $('.login-status .name').text res.name
      $cr.socket.emit 'login', fb_id: res.id, name: res.name

$cr.fb_init = ->
  FB.init
    appId      : '304577099647033' # App ID from the App Dashboard
    status     : true # check the login status upon init?
    cookie     : true # set sessions cookies to allow your server to access the session?
    xfbml      : true # parse XFBML tags on this page?

  FB.Event.subscribe 'auth.authResponseChange', process_login

  FB.getLoginStatus (res) ->
    process_login res

$('.login-status .fb').click ->
  FB.login()