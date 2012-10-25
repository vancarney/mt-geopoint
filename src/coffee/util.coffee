###
  # util.js v 0.1
  # Author: Van Carney
  # Date: 2012-10-12
###
global = exports ? this
(( $ ) ->
  global.isMobile =()->
    (navigator.userAgent.match /Android|webOS|iPhone|iPad|iPod|BlackBerry/i) || false
  global.isSafari =()->
    $.browser.webkit && (!window.navigator.userAgent.match /.*(Chrome)+.*/)
  global.hasFlash =()->
    navigator.mimeTypes["application/x-shockwave-flash"]?
)(jQuery)
