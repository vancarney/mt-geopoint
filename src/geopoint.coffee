# Creates a point on the earth's surface at the supplied latitude / longitude
# @constructor
# @param {Number} lat: latitude in numeric degrees
# @param {Number} lon: longitude in numeric degrees
# @param {Number} [rad=6371]: radius of earth if different value is required from standard 6,371km
class GeoPoint 
  constructor: (lat, lon, rad)->
    rad = 6371 if (typeof rad) == 'undefined'
    @setLat lat
    @setLon lon
    @_radius = if (typeof(rad)=='number' or rad instanceof Number) then rad else (if typeof(rad)=='string' && trim(lon)!='' then +rad else NaN)
    @

  setLat: (lat)->
    if lat?
      @_lat = if ((typeof lat)=='number' or lat instanceof Number) then lat else (if typeof(lat) == 'string' && lat.trim() != '' then +lat else NaN)
    
  setLon: (lon)->
    if lon?
      @_lon = if ((typeof lon)=='number' or lon instanceof Number) then lon else (if typeof(lon)=='string' && lon.trim()!='' then +lon else NaN)
    
  # Returns the distance from this point to the supplied point, in km  (using Haversine formula)
  # from: Haversine formula - R. W. Sinnott, "Virtues of the Haversine", Sky and Telescope, vol 68, no 2, 1984
  #
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @param   {Number} [precision=4]: no of significant digits to use for returned value
  # @returns {Number} Distance in km between this point and destination point
  distanceTo: (point, precision) ->
    # default 4 sig figs reflects typical 0.3% accuracy of spherical model
    precision = 4 if (typeof precision == 'undefined')
    
    R = @_radius
    lat1 = @_lat.toRad()
    lon1 = @_lon.toRad()
    lat2 = point._lat.toRad()
    lon2 = point._lon.toRad()
    dLat = lat2 - lat1
    dLon = lon2 - lon1
  
    a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1) * Math.cos(lat2) * 
            Math.sin(dLon/2) * Math.sin(dLon/2)
    c = 2 * Math.atan2 Math.sqrt(a), Math.sqrt(1-a)
    d = R * c;
    d.toPrecision precision
  
  
  # Returns the (initial) bearing from this point to the supplied point, in degrees
  #   see http://williams.best.vwh.net/avform.htm#Crs
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @returns {Number} Initial bearing in degrees from North
  bearingTo: (point)->
    lat1 = @_lat.toRad()
    lat2 = point._lat.toRad()
    dLon = (point._lon-@_lon).toRad()
  
    y = Math.sin(dLon) * Math.cos(lat2)
    x = Math.cos(lat1)*Math.sin(lat2) -
            Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon)
    brng = Math.atan2(y, x)
    
    (brng.toDeg()+360) % 360
  
  
  # Returns final bearing arriving at supplied destination point from this point; the final bearing 
  # will differ from the initial bearing by varying degrees according to distance and latitude
  #
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @returns {Number} Final bearing in degrees from North
  finalBearingTo : (point)->
    #get initial bearing from supplied point back to this point...
    lat1 = point._lat.toRad()
    lat2 = @_lat.toRad()
    dLon = (@_lon-point._lon).toRad()
  
    y = Math.sin(dLon) * Math.cos(lat2);
    x = Math.cos(lat1)*Math.sin(lat2) -
            Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
    brng = Math.atan2(y, x);
            
    # ... & reverse it by adding 180°
    (brng.toDeg()+180) % 360
  
  inPolygon : (poly)->
    n = poly.length
    inside = false
    p1x = Number poly[0].lat
    p1y = Number poly[0].lon
    for i in [0..(poly.length+1)]
      p2x = Number poly[i % n].lat
      p2y = Number poly[i % n].lon
      if (@_lat > Math.min(p1y,p2y))
        if (@_lat <= Math.max(p1y,p2y))
          if (@_lon <= Math.max(p1x,p2x))
            xinters = (@_lat-p1y)*(p2x-p1x)/(p2y-p1y)+p1x if (p1y != p2y) 
            inside = !inside if (p1x == p2x || @_lon <= xinters)
    p1x = p2x
    p1y = p2y
    inside
  
  
  # Returns the midpoint between this point and the supplied point.
  #   see http://mathforum.org/library/drmath/view/51822.html for derivation
  #
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @returns {GeoPoint} Midpoint between this point and the supplied point
  midpointTo : (point) ->
    lat1 = @_lat.toRad()
    lon1 = @_lon.toRad()
    lat2 = point._lat.toRad()
    dLon = (point._lon-@_lon).toRad()
  
    Bx = Math.cos(lat2) * Math.cos(dLon)
    By = Math.cos(lat2) * Math.sin(dLon)
  
    lat3 = Math.atan2(Math.sin(lat1)+Math.sin(lat2),
                      Math.sqrt( (Math.cos(lat1)+Bx)*(Math.cos(lat1)+Bx) + By*By) )
    lon3 = lon1 + Math.atan2(By, Math.cos(lat1) + Bx);
    lon3 = (lon3+3*Math.PI) % (2*Math.PI) - Math.PI;  # normalise to -180..+180º
    
    new GeoPoint(lat3.toDeg(), lon3.toDeg())
  
  # Returns the destination point from this point having travelled the given distance (in km) on the 
  # given initial bearing (bearing may vary before destination is reached)
  #
  #   see http://williams.best.vwh.net/avform.htm#LL
  #
  # @param   {Number} brng: Initial bearing in degrees
  # @param   {Number} dist: Distance in km
  # @returns {GeoPoint} Destination point
  destinationPoint : (brng, dist) ->
    dist = if (typeof dist) == 'number' then dist else (if (typeof dist)=='string' && dist.trim()!='' then +dist else NaN)
    dist = dist/@_radius  # convert dist to angular distance in radians
    brng = brng.toRad()  
    lat1 = @_lat.toRad()
    lon1 = @_lon.toRad()
  
    lat2 = Math.asin( Math.sin(lat1)*Math.cos(dist) + 
                          Math.cos(lat1)*Math.sin(dist)*Math.cos(brng) )
    lon2 = lon1 + Math.atan2(Math.sin(brng)*Math.sin(dist)*Math.cos(lat1), 
                                 Math.cos(dist)-Math.sin(lat1)*Math.sin(lat2));
    lon2 = (lon2+3*Math.PI) % (2*Math.PI) - Math.PI;  # normalise to -180..+180º
  
    new GeoPoint lat2.toDeg(), lon2.toDeg()
    
  # Returns the point of intersection of two paths defined by point and bearing
  # <i>see http://williams.best.vwh.net/avform.htm#Intersection</i>
  # @param   {LatLon} p1: First point
  # @param   {Number} brng1: Initial bearing from first point
  # @param   {LatLon} p2: Second point
  # @param   {Number} brng2: Initial bearing from second point
  # @returns {LatLon} Destination point (null if no unique intersection defined)    
  intersection : (p1, brng1, p2, brng2) ->
    brng1 = if typeof brng1 == 'number' then brng1 else (if typeof brng1 == 'string' && trim(brng1) != '' then +brng1 else NaN)
    brng2 = if typeof brng2 == 'number' then brng2 else (if typeof brng2 == 'string' && trim(brng2)!='' then +brng2 else NaN)
    lat1 = p1._lat.toRad()
    lon1 = p1._lon.toRad()
    lat2 = p2._lat.toRad()
    lon2 = p2._lon.toRad()
    brng13 = brng1.toRad()
    brng23 = brng2.toRad()
    dLat = lat2-lat1
    dLon = lon2-lon1
    
    dist12 = 2*(Math.asin Math.sqrt Math.sin(dLat/2)*Math.sin(dLat/2) + (Math.cos lat1)*(Math.cos lat2)*(Math.sin dLon/2)*(Math.sin dLon/2) ) 
    return null if (dist12 == 0)
    
    # initial/final bearings between points
    brngA = Math.acos( ( Math.sin(lat2) - Math.sin(lat1)*Math.cos(dist12) ) / 
      ( Math.sin(dist12)*Math.cos(lat1) ) );
    brngA = 0 if (isNaN(brngA))  # protect against rounding
    brngB = Math.acos( ( Math.sin(lat1) - Math.sin(lat2)*Math.cos(dist12) ) / 
      ( Math.sin(dist12)*Math.cos(lat2) ) )
    
    if (Math.sin(lon2-lon1) > 0)
      brng12 = brngA
      brng21 = 2*Math.PI - brngB
    else
      brng12 = 2*Math.PI - brngA
      brng21 = brngB
    
    alpha1 = (brng13 - brng12 + Math.PI) % (2*Math.PI) - Math.PI;  # angle 2-1-3
    alpha2 = (brng21 - brng23 + Math.PI) % (2*Math.PI) - Math.PI;  # angle 1-2-3
    
    return null if ((Math.sinalpha1)==0 && (Math.sin alpha2)==0) or (Math.sin alpha1)*(Math.sin alpha2) < 0  # infinite or ambiguous intersection
    
    alpha3  = Math.acos -Math.cos(alpha1)*Math.cos(alpha2) + Math.sin(alpha1)*Math.sin(alpha2)*Math.cos(dist12)
    dist13  = Math.atan2 Math.sin(dist12)*Math.sin(alpha1)*Math.sin(alpha2), Math.cos(alpha2)+Math.cos(alpha1)*Math.cos(alpha3)
    lat3    = Math.asin Math.sin(lat1)*Math.cos(dist13) + Math.cos(lat1)*Math.sin(dist13)*Math.cos(brng13) 
    dLon13  = Math.atan2 Math.sin(brng13)*Math.sin(dist13)*Math.cos(lat1), Math.cos(dist13)-Math.sin(lat1)*Math.sin(lat3)
    lon3    = lon1+dLon13
    lon3    = (lon3+3*Math.PI) % (2*Math.PI) - Math.PI;  # normalise to -180..+180º
    
    new GeoPoint lat3.toDeg(), lon3.toDeg()

  # Returns the distance from this point to the supplied point, in km, travelling along a rhumb line
  #   see http://williams.best.vwh.net/avform.htm#Rhumb
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @returns {Number} Distance in km between this point and destination point
  rhumbDistanceTo : (point) ->
    lat1 = @_lat.toRad()
    lat2 = point._lat.toRad()
    dLat = (point._lat-@_lat).toRad();
    dLon = Math.abs(point._lon-@_lon).toRad()
    
    dPhi = Math.log Math.tan(lat2/2+Math.PI/4)/Math.tan(lat1/2+Math.PI/4)
    q = if (!isNaN dLat/dPhi) then dLat/dPhi else Math.cos lat1  # E-W line gives dPhi=0
    # if dLon over 180° take shorter rhumb across 180° meridian:
    dLon = 2*Math.PI - dLon if (dLon > Math.PI)
    dist = (Math.sqrt dLat*dLat + q*q*dLon*dLon) * @_radius
    
    dist.toPrecisionFixed 4  # 4 sig figs reflects typical 0.3% accuracy of spherical model
  
  
  # Returns the bearing from this point to the supplied point along a rhumb line, in degrees
  #
  # @param   {GeoPoint} point: Latitude/longitude of destination point
  # @returns {Number} Bearing in degrees from North
  rhumbBearingTo : (point) ->
    lat1 = @_lat.toRad()
    lat2 = @_lat.toRad()
    dLon = (@_lon-@_lon).toRad()
    
    dPhi = Math.log(Math.tan(lat2/2+Math.PI/4)/Math.tan(lat1/2+Math.PI/4))
    if (Math.abs(dLon) > Math.PI)
      dLon = if dLon>0 then -(2*Math.PI-dLon) else (2*Math.PI+dLon)  
    brng = Math.atan2(dLon, dPhi)
    
    (brng.toDeg()+360) % 360
  
  
  # Returns the destination point from this point having travelled the given distance (in km) on the 
  # given bearing along a rhumb line
  # @param   {Number} brng: Bearing in degrees from North
  # @param   {Number} dist: Distance in km
  # @returns {GeoPoint} Destination point
  rhumbDestinationPoint : (brng, dist) ->
    d = parseFloat(dist)/@_radius  # d = angular distance covered on earth's surface
    lat1 = @_lat.toRad()
    lon1 = @_lon.toRad()
    brng = brng.toRad()
  
    lat2 = lat1 + (d*Math.cos brng)
    dLat = lat2-lat1
    dPhi = (Math.log Math.tan lat2/2+Math.PI/4)/(Math.tan lat1/2+Math.PI/4)
    q = if (!isNaN dLat/dPhi) then dLat/dPhi else Math.cos lat1  # E-W line gives dPhi=0
    dLon = d*(Math.sin brng)/q;
    # check for some daft bugger going past the pole
    if (Math.abs lat2) > Math.PI/2
      lat2 = if lat2>0 then Math.PI-lat2 else -(Math.PI-lat2)
    lon2 = (lon1+dLon+3*Math.PI)%(2*Math.PI) - Math.PI
    new GeoPoint lat2.toDeg(), lon2.toDeg()
  
  # Returns the latitude of this point; signed numeric degrees if no format, otherwise format & dp 
  # as per Geo.toLat()
  #
  # @param   {String} [format]: Return value as 'd', 'dm', 'dms'
  # @param   {Number} [dp=0|2|4]: No of decimal places to display
  # @returns {Number|String} Numeric degrees if no format specified, otherwise deg/min/sec
  #
  # @requires Geo
  lat : (format, dp) ->
    return @_lat if (typeof format == 'undefined')
    @toLat(@_lat, format, dp)
    
  # Returns the longitude of this point; signed numeric degrees if no format, otherwise format & dp 
  # as per Geo.toLon()
  # @param   {String} [format]: Return value as 'd', 'dm', 'dms'
  # @param   {Number} [dp=0|2|4]: No of decimal places to display
  # @returns {Number|String} Numeric degrees if no format specified, otherwise deg/min/sec
  # @requires Geo
  lon : (format, dp) ->
    return @_lon if (typeof format == 'undefined')
    @toLon(@_lon, format, dp);
  
  # Returns a string representation of this point; format and dp as per lat()/lon()
  # @param   {String} [format]: Return value as 'd', 'dm', 'dms'
  # @param   {Number} [dp=0|2|4]: No of decimal places to display
  # @returns {String} Comma-separated latitude/longitude
  # @requires Geo
  toString : (format, dp) ->
    format = 'dms' if (typeof format == 'undefined')
    return '-,-' if (isNaN(@_lat) || isNaN(@_lon))
    "#{GeoPoint.toLat @_lat, format, dp},#{GeoPoint.toLon @_lon, format, dp}"
  
#  Geodesy representation conversion functions (c) Chris Veness 2002-2011                        
#   - www.movable-type.co.uk/scripts/latlong.html                                                
#                                                                                               
#  Sample usage:                                                                                 
#    var lat = Geo.parseDMS('51Â° 28â€² 40.12â€³ N');                                              
#    var lon = Geo.parseDMS('000Â° 00â€² 05.31â€³ W');                                                
#    var p1 = new GeoPoint(lat, lon);                                                              
# 

# Parses string representing degrees/minutes/seconds into numeric degrees
#
# This is very flexible on formats, allowing signed decimal degrees, or deg-min-sec optionally
# suffixed by compass direction (NSEW). A variety of separators are accepted (eg 3Âº 37' 09"W) 
# or fixed-width format without separators (eg 0033709W). Seconds and minutes may be omitted. 
# (Note minimal validation is done).
#
# @param   {String|Number} dmsStr: Degrees or deg/min/sec in variety of formats
# @returns {Number} Degrees as decimal number
# @throws  {TypeError} dmsStr is an object, perhaps DOM object without .value?
GeoPoint.parseDMS = (dmsStr)->
  throw new TypeError('GeoPoint.parseDMS - dmsStr is [DOM?] object') if !(deg instanceof Number) and typeof deg == 'object'
  
  # check for signed decimal degrees without NSEW, if so return it directly
  return Number dmsStr if (typeof dmsStr) == 'number' && isFinite dmsStr
  
  # strip off any sign or compass dir'n & split out separate d/m/s
  dms = String(dmsStr).trim().replace(/^-/,'').replace(/[NSEW]$/i,'').split /[^0-9.,]+/
  dms.splice(dms.length-1) if (dms[dms.length-1] == '') # from trailing symbol
  
  return NaN if (dms == '') 
  
  # and convert to decimal degrees...
  switch (dms.length) 
    when 3 then deg = dms[0]/1 + dms[1]/60 + dms[2]/3600 # interpret 3-part result as d/m/s
    when 2 then deg = dms[0]/1 + dms[1]/60 # interpret 2-part result as d/m
    when 1 then deg = dms[0]  # just d (possibly decimal) or non-separated dddmmss  
    else return NaN
  deg = -deg if (/^-|[WS]$/i.test dmsStr.trim()) # take '-', west and south as -ve
  Number deg

# Convert decimal degrees to deg/min/sec format
#  - degree, prime, double-prime symbols are added, but sign is discarded, though no compass
#    direction is added
# @private
# @param   {Number} deg: Degrees
# @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
# @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
# @returns {String} deg formatted as deg/min/secs according to specified format
# @throws  {TypeError} deg is an object, perhaps DOM object without .value?
GeoPoint.toDMS = (deg, format, dp) ->
  throw new TypeError('GeoPoint.toDMS - deg is [DOM?] object') if !(deg instanceof Number) and typeof deg == 'object'
  return NaN if (isNaN deg) # give up here if we can't make a number from deg
  
  # default values
  format = 'dms' if (typeof format) == 'undefined'
  if (typeof dp) == 'undefined'
    switch (format)
      when 'd' then   dp = 4
      when 'dm' then  dp = 2
      when 'dms' then dp = 0
      else 
        format = 'dms' 
        dp = 0  # be forgiving on invalid format

  deg = Math.abs deg  # (unsigned result ready for appending compass dir'n)
  
  switch (format)
    when 'd' then (
      d = deg.toFixed dp    # round degrees
      d = "0#{d}" if (d<100)  # pad with leading zeros
      d = "0#{d}" if (d<10)
      return "#{d}\u00B0"     # add º symbol
    )
    when 'dm' then (
      min = (deg*60).toFixed dp  # convert degrees to minutes & round
      d = Math.floor(min / 60)    # get component deg/min
      m = (min % 60).toFixed(dp)  # pad with trailing zeros
      d = "0#{d}" if (d<100)            # pad with leading zeros
      d = "0#{d}" if (d<10) 
      m = "0#{m}" if (m<10) 
      return "#{d}\u00B0#{m}\u2032"  # add Âº, ' symbols
    )
    when 'dms' then (
      sec = (deg*3600).toFixed dp  # convert degrees to seconds & round
      d = Math.floor (sec / 3600)   # get component deg/min/sec
      m = Math.floor (sec/60) % 60
      s = (sec % 60).toFixed dp    # pad with trailing zeros
      d = "0#{d}"  if (d<100)           # pad with leading zeros
      d = "0#{d}" if (d<10) 
      m = "0#{m}" if (m<10) 
      s = "0#{s}" if (s<10) 
      return "#{d}\u00B0#{m}\u2032#{s}\u2033"  # add º, ', " symbols
    )

# Convert numeric degrees to deg/min/sec latitude (suffixed with N/S)
#
# @param   {Number} deg: Degrees
# @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
# @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
# @returns {String} Deg/min/seconds
GeoPoint.toLat = (deg, format, dp) ->
  lat = GeoPoint.toDMS deg, format, dp
  if !lat or lat == '' then '' else "#{lat.slice(1)}#{if deg<0 then 'S' else 'N'}"  # knock off initial '0' for lat!

# Convert numeric degrees to deg/min/sec longitude (suffixed with E/W)
#
# @param   {Number} deg: Degrees
# @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
# @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
# @returns {String} Deg/min/seconds
GeoPoint.toLon = (deg, format, dp)->
  lon = GeoPoint.toDMS(deg, format, dp);
  if !lon or lon == '' then '' else "#{lon}#{if deg<0 then 'W' else 'E'}"

# Convert numeric degrees to deg/min/sec as a bearing (0Âº..360Âº)
# @param   {Number} deg: Degrees
# @param   {String} [format=dms]: Return value as 'd', 'dm', 'dms'
# @param   {Number} [dp=0|2|4]: No of decimal places to use - default 0 for dms, 2 for dm, 4 for d
# @returns {String} Deg/min/seconds
GeoPoint.toBrng = (deg, format, dp)->
  deg = (Number(deg)+360) % 360  # normalise -ve values to 180Âº..360Âº
  brng =  GeoPoint.toDMS deg, format, dp
  brng.replace '360', '0' # just in case rounding took us up to 360Âº!
    
 # ---- extend Number object with methods for converting degrees/radians

# Converts numeric degrees to radians 
if (typeof Number.prototype.toRad) == "undefined"
  Number.prototype.toRad = ->
    @ * Math.PI / 180

# Converts radians to numeric (signed) degrees */
if (typeof Number.prototype.toDeg) == "undefined"
  Number.prototype.toDeg = ->
    @ * 180 / Math.PI

# Formats the significant digits of a number, using only fixed-point notation (no exponential)
# 
# @param   {Number} precision: Number of significant digits to appear in the returned string
# @returns {String} A string representation of number which contains precision significant digits
if (typeof Number.prototype.toPrecisionFixed) == "undefined"
  Number.prototype.toPrecisionFixed = (precision) ->
    return 'NaN' if (isNaN @)
    numb = if @ < 0 then -(@) else @  # can't take log of -ve number...
    sign = if @ < 0 then '-' else ''
    
    if (numb == 0) # can't take log of zero, just format with precision zeros
      n = '0.'
      while (precision--) 
        n += '0'
      return n 

    scale = Math.ceil(Math.log(numb)*Math.LOG10E);  # no of digits before decimal
    n = String(Math.round(numb * Math.pow(10, precision-scale)))
    if (scale > 0)   # add trailing zeros & insert decimal as required
      l = scale - n.length
      while (l-- > 0) 
        n = n + '0'
      n = "#{n.slice(0,scale)}.#{n.slice(scale)}" if (scale < n.length)
    else        # prefix decimal and leading zeros if required
      while (scale++ < 0) 
        n = "0#{n}"
      n = "0.#{n}"
    return sign + n
# Returns center Coordinates of given Polygon
GeoPoint.centroid = (poly) ->
  x = 0
  y = 0
  for coords in poly
    do (coords)=>
      x = x + Number coords._lon
      y = y + Number coords._lat
  new GeoPoint y/poly.length, x/poly.length
# Trims whitespace from string (q.v. blog.stevenlevithan.com/archives/faster-trim-javascript) 
if (typeof String.prototype.trim) == "undefined"
  String.prototype.trim = ()=>
    return String(@).replace(/^\s\s*/, '').replace /\s\s*$/, ''
    
if exports?
  module.exports = (lat,lon)-> new GeoPoint lat, lon