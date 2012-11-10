$cr = window.$cr = window.$cr or {}

$cr.fb_init = ->
  FB.init
    appId      : '304577099647033' # App ID from the App Dashboard
    status     : true # check the login status upon init?
    cookie     : true # set sessions cookies to allow your server to access the session?
    xfbml      : true # parse XFBML tags on this page?

  alert 'fb init!'