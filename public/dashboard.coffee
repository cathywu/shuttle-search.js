# vim: set tabstop=2 shiftwidth=2 softtabstop=2 expandtab :
rootDir = "/shuttle-dashboard-js-data"
addrDir = "#{rootDir}/addresses"
stopDir = "#{rootDir}/stops"
bugDir = "#{rootDir}/bugs"

DIR2TYPE = {'addresses':'addr', \
           'stops': 'stop', \
           'bugs':  'bug', \
           'active':'(none)', \
           'done': '(none)'}

beachMarker = 'images/beachflag.png'
crosshairMarker = 'images/crosshair.png'
stopMarker = 'images/stop.png'
addrMarker = 'images/dropbox.png'
addrPurpleMarket = 'images/dropbox_purple.png'
# addrMarker = 'images/house.png'

# Start/Finish icons
icons = {
 beach: new google.maps.MarkerImage(
  # URL
  beachMarker,
  # (width,height)
  new google.maps.Size( 20, 32 ),
  # The origin point (x,y)
  new google.maps.Point( 0, 0 ),
  # The anchor point (x,y)
  new google.maps.Point( 0, 32 )
 ),
 house: new google.maps.MarkerImage(
  'images/house.png',
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 Marina: new google.maps.MarkerImage(
  stopMarker,
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 Mission: new google.maps.MarkerImage(
  stopMarker,
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 stop: new google.maps.MarkerImage(
  stopMarker,
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 crosshair: new google.maps.MarkerImage(
  crosshairMarker,
  new google.maps.Size( 40, 40 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 20, 28 )
 ),
 ChinaBasin: new google.maps.MarkerImage(
  'images/chinabasin.png',
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 MissionBayEast: new google.maps.MarkerImage(
  'images/missionbay.png',
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 MissionBayWest: new google.maps.MarkerImage(
  'images/missionbay.png',
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 ),
 '(undefined)': new google.maps.MarkerImage(
  beachMarker,
  new google.maps.Size( 20, 32 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 0, 32 )
 )
}

# Aliases
# ------------------------------------------------------------------------------
delay = (ms, func) -> setTimeout func, ms
randomColor = () -> '#'+Math.floor(Math.random()*16777215).toString(16)

zip = (arr1, arr2) ->
  basic_zip = (el1, el2) -> [el1, el2]
  zipWith basic_zip, arr1, arr2

zipWith = (func, arr1, arr2) ->
  min = Math.min arr1.length, arr2.length
  ret = []
  for i in [0...min]
    ret.push func(arr1[i], arr2[i])
  ret

# Toggles
# ------------------------------------------------------------------------------
$('#layer-addresses').click (state) ->
  if this.checked
    window.addrLayer.show(window.map)
  else
    window.addrLayer.hide()

$('#layer-stops').click (state) ->
  if this.checked
    stopLayer.show(window.map) for stopLayer in window.stopLayers
  else
    stopLayer.hide() for stopLayer in window.stopLayers

$('.entry-toggle-button').click ->
  $(this.name).toggle()

# Layer toggles
# ------------------------------------------------------------------------------
class LayerOverlay
  constructor: () ->
    @visible = null
    @overlays = []
    @prototype = new google.maps.OverlayView() # extend OverlayView
    @prototype.addOverlay = (overlay) =>
      @overlays.push(overlay)
    @prototype.updateOverlays = =>
      (overlay.setMap(@prototype.getMap()) for overlay in @overlays)
    @prototype.draw = (->)
    @prototype.onAdd = @prototype.updateOverlays
    @prototype.onRemove = @prototype.updateOverlays
    @center = new google.maps.LatLng(37.776019, -122.393085)
    @directionsDisplay = null

  show: (map) =>
    @visible = true
    @prototype.setMap(map)
    @prototype.updateOverlays()
    if @directionsDisplay
        @directionsDisplay.setMap(map)

  hide: =>
    @visible = null
    @prototype.setMap(null)
    @prototype.updateOverlays()
    if @directionsDisplay
        @directionsDisplay.setMap(null)

  toggle: (map) =>
    if @visible
      @hide()
    else
      @show(map)

  mapRefresh: (center) =>
    google.maps.event.trigger( @prototype.getMap(), 'resize' )
    @prototype.getMap().setCenter(center)
    if @centerMarker
      @centerMarker.setMap(null)
    @centerMarker = new google.maps.Marker
      position: center,
      map: @map,
      icon: icons.crosshair
    window.scrollTo 0,0

  plot: (lat, lon, marker, label, delayTime, callback) =>
    delay delayTime, =>
      newMarker = new google.maps.Marker
        position: new google.maps.LatLng(lat, lon)
        map: @prototype.getMap()
        icon: marker
        title: label
      @prototype.addOverlay(newMarker)
      callback()

  plotAddr: (entry, callback) =>
    marker = addrMarker
    label = entry.name
    delayTime = 5
    @plot(entry.lat, entry.lon, marker, label, delayTime, callback)

  addSeries: (addrs) =>
    if addrs.length > 0
      async.eachSeries addrs, @plotAddr, =>
        @mapRefresh @center
        console.log 'Done adding layer'

  # TODO merge with plot()
  makeMarker: (position, icon, title) =>
    newMarker = new google.maps.Marker
      position: position,
      map: @prototype.getMap(),
      icon: icon,
      title: title
    @prototype.addOverlay(newMarker)

  plotRoute: (stops, callback) =>
    rendererOptions = {
      map: @prototype.getMap(),
      suppressMarkers: true,
      polylineOptions:{strokeColor:randomColor()},
      preserveViewport:true
      }
    @directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions)
    wps = ({location: new google.maps.LatLng(stop.lat,stop.lon)} for stop in stops[0..stops.length-2])
    org = new google.maps.LatLng(stops[stops.length-1].lat,stops[stops.length-1].lon)
    dest = new google.maps.LatLng(stops[stops.length-1].lat,stops[stops.length-1].lon)
    request = {
      origin: org,
      destination: dest,
      waypoints: wps,
      travelMode: google.maps.DirectionsTravelMode.DRIVING
      }
    directionsService = new google.maps.DirectionsService()
    directionsService.route request, (response, status) =>
      if (status == google.maps.DirectionsStatus.OK)
        @directionsDisplay.setDirections(response)
        leg = response.routes[0].legs[0]
        for leg,i in response.routes[0].legs
          ind = (i-1+stops.length) % stops.length
          label = "#{stops[ind].route} - Stop #{stops[ind].name.split('$',2)[0]} - #{stops[ind].name.split('$',2)[1]} || Next stop: #{leg.duration.text} (#{leg.distance.text})"
          @makeMarker leg.start_location, icons[stops[0].route], label
      else
        alert ('failed to get directions')
    callback()

  plotTransit: (directions, callback) =>
    rendererOptions = {
      map: @prototype.getMap(),
      suppressMarkers: true,
      polylineOptions:{strokeColor:"#000000"},
      preserveViewport:true
      }
    @directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions)
    @directionsDisplay.setDirections(directions)
    @makeMarker directions.routes[0].legs[0].start_location, icons.house, directions.routes[0].legs[0].start_address
    @makeMarker directions.routes[0].legs[0].end_location, icons.stop, directions.routes[0].legs[0].end_address
    callback()

#
# GOOGLE MAPS FUNCTIONS
# ------------------------------------------------------------------------------

plotLatLons = (map, marker, latlons) ->
  for latlon in latlons
    beachMarker = new google.maps.Marker
      position: latlon,
      map: map,
      icon: marker

# Controller/View for the application.
class Dashboard
  # @param {Dropbox.Client} dbClient a non-authenticated Dropbox client
  # @param {DOMElement} root the app's main UI element
  constructor: (@dbClient, @root) ->
    @$root = $ @root
    @entryTemplate = $('#entry-template').html().trim()
    @transitTemplate = $('#transit-template').html().trim()

    @$activeList = $ '#active-entry-list', @$root
    @$doneList = $ '#done-entry-list', @$root
    @$addrList = $ '#addr-entry-list', @$root
    @$stopList = $ '#stop-entry-list', @$root
    @$bugList = $ '#bug-entry-list', @$root
    @$transitList = $ '#transit-results-list', @$root
    @transitOverlayList = []

    # Google Maps
    center = new google.maps.LatLng(37.776019, -122.393085)
    # @centerMarker = @mapRefresh center
    @hq = new google.maps.LatLng(37.776019, -122.393085)
    @map = @createGoogleMap(center)
    window.map = @map # make map GLOBAL
    @plotAddrs(@map, beachMarker, ['185 berry st, sf']) # office
    # render full map hack
    delay 1000, =>
      google.maps.event.trigger( @map, 'resize' )
      @map.setCenter(center)
      $('#map-page').show()

    @typeMap = {'addr': {dir: addrDir, list: @$addrList}, \
               'stop': {dir: stopDir, list: @$stopList}, \
               'bug':  {dir: bugDir, list: @$bugList}, \
               '(none)':{dir: "#{rootDir}/active", list: @$activeList} }
    $('#signout-button').click (event) => @onSignOut event

    @dbClient.authenticate (error, data) =>
      return @showError(error) if error
      @dbClient.getAccountInfo (error, userInfo) =>
        return @showError(error) if error
        $('#user-name', @$root).text userInfo.name
      @entries = new Entries @, @dbClient
      @entries.load =>
        @wire()
        @render()
        # Plot addresses
        addrLayer = new LayerOverlay()
        # addrLayer.show(@map)
        addrLayer.addSeries @entries.addr
        window.addrLayer = addrLayer # made addrLayer GLOBAL

        # for route,stops of @entries.stop
        #   if stops.length > 0
        #     async.eachSeries stops, @plotStop, =>
        #       @mapRefresh center
        #       console.log "Done plotting #{route} stops"

        # Plot shuttle routes
        routes = (stops for route,stops of @entries.stop)
        window.stopLayers = null 
        async.mapSeries routes, @plotRoute, (err, results) =>
          window.stopLayers = results
          @mapRefresh center
          console.log 'Done adding route layers'

        window.userLayers = {}

        # Compute public transit times
        # if @entries.addr.length > 0
        #   async.eachSeries @entries.addr, @computePublicTransitTime, =>
        #     @mapRefresh center
        #     console.log 'Done computing public transit times'

        @$root.removeClass 'hidden'

  #
  # GOOGLE MAPS FUNCTIONS
  # ----------------------------------------------------------------------------

  #
  # Initializes and returns a map centering it on
  # the coordinates provided
  #
  createGoogleMap: (centerPoint) ->
    map = new google.maps.Map $("#map-canvas")[0],
      center: centerPoint
      mapTypeId: google.maps.MapTypeId.ROADMAP
      zoom: 13
      streetViewControl: false
      panControl: false

    styles = [
      {
        stylers: [
          { hue: "#649cd1" },
          { saturation: -20 }
        ]
      },{
        featureType: "road",
        elementType: "geometry",
        stylers: [
          { lightness: 100 },
          { visibility: "simplified" }
        ]
      }
    ]
    
    map.setOptions({styles: styles})

    # transitLayer = new google.maps.TransitLayer()
    # transitLayer.setMap map

    return map

  plotRoute: (route, callback) =>
    delay 5, =>
      stopLayer = new LayerOverlay()
      # stopLayer.show(@map)
      stopLayer.plotRoute route, =>
        console.log 'Done adding route layer'
        callback(null, stopLayer)

  mapRefresh: (center) =>
    google.maps.event.trigger( @map, 'resize' )
    @map.setCenter(center)
    if @centerMarker
      @centerMarker.setMap(null);
    @centerMarker = new google.maps.Marker
      position: center,
      map: @map,
      icon: icons.crosshair
    window.scrollTo 0,0

  # FIXME @plotLatLons function not accessible?
  plotLatLons: (map, marker, latlons) ->
    layer = new LayerOverlay()
    for latlon in latlons
      beachMarker = new google.maps.Marker
        position: latlon,
        map: map,
        icon: marker
      layer.addOverlay(beachMarker)
    return layer
  
  plotAddrs: (map, marker, addrs) =>
    geocoder = new google.maps.Geocoder()
    counter = 0
    latlons = []
    (geocoder.geocode( { 'address': addr}, (results, status) ->
      counter += 1
      if (status == google.maps.GeocoderStatus.OK)
        latlons.push results[0].geometry.location
      else
        console.log status + " " + addr
      if counter == addrs.length
        console.log "Successfully geocoded: #{latlons.length} of #{addrs.length}"
        addrLayer = plotLatLons(map, marker, latlons)
        console.log addrLayer
        google.maps.event.trigger( map, 'resize' )
        return addrLayer )\
      for addr in addrs)

  plot: (lat, lon, marker, label, delayTime, callback) =>
    delay delayTime, =>
      newMarker = new google.maps.Marker
        position: new google.maps.LatLng(lat, lon)
        map: @map
        icon: marker
        title: label
      callback()

  plotStop: (entry, callback) =>
    marker = stopMarker
    label = "#{entry.route} - Stop #{entry.name.split('$',2)[0]} - #{entry.name.split('$',2)[1]}"
    delayTime = 10
    @plot(entry.lat, entry.lon, marker, label, delayTime, callback)

  plotPath: (lat, lon, marker, label, delayTime, callback) =>
    delay delayTime, =>
      newMarker = new google.maps.Marker
        position: new google.maps.LatLng(lat, lon)
        map: @map
        icon: marker
        title: label
      callback()

  computeTransitTimeHelper: (org, dest, time, mode, stop, callback) =>
    delay 1000, =>
      if mode == 'arrive-by'
        request = {
          origin: org,
          destination: dest,
          travelMode: google.maps.DirectionsTravelMode.TRANSIT
          transitOptions: { arrivalTime: time.nextDate() }
          }
      else if mode == 'depart-at' || mode == 'leave-by'
        request = {
          origin: org,
          destination: dest,
          travelMode: google.maps.DirectionsTravelMode.TRANSIT
          transitOptions: { departureTime: time.nextDate() }
          }

      directionsService = new google.maps.DirectionsService()
      directionsService.route request, (response, status) =>
        if (status == google.maps.DirectionsStatus.OK)
            # console.log response.routes[0].legs
            # console.log response.routes[0].legs[0].duration.text
          callback(response, stop)
        else
          if status == "OVER_QUERY_LIMIT"
            @computeTransitTimeHelper(org, dest, time, mode, stop, callback)
          else
            console.log "Error getting directions: #{status}"
            callback(response, stop)

  computePublicTransitTime: (entry, callback) =>
    org = new google.maps.LatLng(entry.lat,entry.lon)
    refTime = new Time $('#timepicker').val()
    mode = $('#timingpicker').val()
    @computeTransitTimeHelper org, @hq, refTime, mode, null, (response) ->
      callback(response)

  computeTransitTime: (entry, stops, callback) =>
    org = new google.maps.LatLng(entry.lat,entry.lon)
    allstops = []
    for k,v of stops
      allstops = allstops.concat(v[0..v.length-2])

    # public transit route to HQ
    refTime = new Time $('#timepicker').val()
    mode = $('#timingpicker').val()
    @computeTransitTimeHelper org, @hq, refTime, mode, null, (response) ->
      console.log response.routes[0].legs[0].duration.text
      layer = new LayerOverlay()
      layer.plotTransit response, (->)
      layer.show(window.map) # display one result
      duration = response.routes[0].legs[0].duration.value
      distance = response.routes[0].legs[0].distance.value
      window.userLayers["#{duration} #{distance}"] = \
        directions: response,
        layer: layer,
        stop: null
      # callback(response)

    # public transit route to each shuttle stop
    for stop in allstops
      dest = new google.maps.LatLng(stop.lat,stop.lon)
      if $('#timingpicker').val() == 'depart-at' || $('#timingpicker').val() == 'leave-now'
        time = refTime
      else
        time = stop.getPrevTime(refTime)

      @computeTransitTimeHelper org, dest, time, mode, stop, (response, stop) =>
        distance = response.routes[0].legs[0].distance.value

        departureTime = response.routes[0].legs[0].departure_time.value.getTime()
        arrivalTime = new Time response.routes[0].legs[0].arrival_time.text
        shuttleArrivalTime = stop.getNextDest(arrivalTime)
        duration = (shuttleArrivalTime.nextDate().getTime() - departureTime)/1000

        layer = new LayerOverlay()
        layer.plotTransit response, (->)
        window.userLayers["#{duration} #{distance}"] = \
          directions: response,
          layer: layer,
          stop: stop
        @refreshDirections()
        # callback(response)

  #
  # RENDER FUNCTIONS
  # ----------------------------------------------------------------------------

  # Re-renders all the data.
  render: =>
    @$activeList.empty()
    @$doneList.empty()
    @$addrList.empty()
    @$stopList.empty()
    @$bugList.empty()
    for entries in [@entries.active, @entries.done, @entries.addr, @entries.bug]
        @renderEntry(entry) for entry in entries
    console.log @entries.stop
    for route,stops of @entries.stop
        @renderEntry(entry) for entry in stops
    @

  # Renders the list element representing a entry.
  #
  # @param {Entry} entry the entry to be rendered
  # @return {jQuery<li>} jQuery wrapper for the DOM representing the entry
  $entryDom: (entry) =>
    $entry = $ @entryTemplate
    $('.entry-name', $entry).text entry.name
    $('.entry-remove-button', $entry).click (event) => @onRemoveEntry event, entry
    if entry.done
      $('.entry-goto-button', $entry).addClass 'hidden'
      $('.entry-active-button', $entry).click (event) =>
        @onActiveEntry event, entry
    else
      $('.entry-active-button', $entry).addClass 'hidden'
      $('.entry-goto-button', $entry).click (event) =>
        @mapRefresh new google.maps.LatLng(entry.lat,entry.lon)
      # $('.entry-goto-button', $entry).click (event) => @onGoToEntry event, entry
    $entry

  # Renders a entry into the list that it belongs to.
  renderEntry: (entry) =>
    $list = @typeMap[entry.type].list
    # $list = if entry.done then @$doneList else @$activeList
    $list.append @$entryDom(entry)

  # Entry render wrapper 
  toRender: (entry) ->
    =>
      @renderEntry entry

  $transitDom: (duration, directions) =>
    $entry = $ @transitTemplate
    duration = duration/60
    $('.transit-duration', $entry).text "#{duration.toFixed(0)} min"

    departureTime = new Time directions.directions.routes[0].legs[0].departure_time.text
    arrivalTime = new Time directions.directions.routes[0].legs[0].arrival_time.text
    if directions.stop # Private shuttle option
      arrivalTime = directions.stop.getNextDest(arrivalTime)
    $('.transit-time', $entry).text "#{departureTime} - #{arrivalTime}"

    steps = []
    for leg in directions.directions.routes[0].legs[0].steps
        if leg.travel_mode == "WALKING"
            steps.push "Walk"
        else if leg.travel_mode == "TRANSIT"
            if leg.transit.line.short_name
              steps.push leg.transit.line.short_name
            else
              steps.push leg.transit.line.name
    if directions.stop
        directions.directions.routes[0].legs[0].arrival_time.text
        # TODO add wait time
        # steps.push 
        steps.push directions.stop.route
    $('.transit-steps', $entry).text steps.join(' > ')
    $entry

  renderDirections: (duration, directions) =>
    $list = @$transitList
    $list.append @$transitDom(duration, directions)

  refreshDirections: =>
    @$transitList.empty()
    @transitOverlayList = []
    c = 0
    sorted_keys = Object.keys(window.userLayers).sort()
    for key in sorted_keys
        @renderDirections(key.split(' ',2)[0],window.userLayers[key])
        @transitOverlayList.push window.userLayers[key]
        # v.layer.show(@map)
        c = c+1
        break if c >= 9
    # TODO would like to show top result, but incremental loading makes this
    # awkward right now
    # @transitOverlayList[0].layer.show(@map)

    # Replace event listeners with new ones that toggle overlays
    $('.transit-result').unbind('click');
    $('.transit-result').click (x) =>
      $(x.currentTarget).siblings().removeClass('selected')
      $(x.currentTarget).addClass('selected')
      index = $('li.transit-result').index(x.currentTarget)
      (transit.layer.hide() for k,transit of window.userLayers)
      @transitOverlayList[index].layer.toggle(@map)

  toRenderDirections: (directions) ->
    =>
      @renderEntry directions

  # addEntry wrapper, with delay (for async.js)
  toAddEntry: (entry, callback) =>
    # delay 150, => # good enough for dropbox rate limiting
    delay 200, =>
      if entry.name == "(no name)"
        callback()
      else
        geocoder = new google.maps.Geocoder()
        geocoder.geocode( { 'address': entry.name}, (results, status) =>
          if (status == google.maps.GeocoderStatus.OK)
            entry.name = results[0].formatted_address.replace('/',' or ')
            if @entries.find entry
              console.log "You already have at #{entry.name} on your list!"
            else
              @entries.addEntry entry, @toRender entry
              lat = results[0].geometry.location.lat().toPrecision(8)
              lon = results[0].geometry.location.lng().toPrecision(8)
              newMarker = new google.maps.Marker
                position: new google.maps.LatLng(lat, lon),
                map: @map,
                icon: addrMarker
              latlonEntry = new Entry name: "#{entry.name}/gps$#{lat},#{lon}", \
                  done: false, type: 'addr'
              @entries.addSubEntry latlonEntry, @toRender entry
            callback()
          else
            if @entries.find entry
              window.alert "You already have at #{entry.name} on your list!"
              callback()
            else if status == "OVER_QUERY_LIMIT"
              delay 500, =>
                @toAddEntry(entry, callback)
            else
              console.log "Error geocoding: " + status + " " + entry.name
              callback() )

  # addRoute wrapper, with delay (for async.js)
  toAddRoute: (entry, callback) =>
    # delay 150, => # good enough for dropbox rate limiting
    delay 200, =>
      if entry.name == "(no name)"
        callback()
      else
        geocoder = new google.maps.Geocoder()
        geocoder.geocode( { 'address': entry.address}, (results, status) =>
          if (status == google.maps.GeocoderStatus.OK)
            entry.address = results[0].formatted_address.replace('/',' or ')
            entry.path = "#{@typeMap.stop.dir}/#{entry.route}/#{entry.number}$#{entry.address}"
            if @entries.find entry
              console.log "You already have at #{entry.name} on your list!"
            else
              # add folder for the stop address
              @entries.addEntry entry, @toRender entry

              # add file for the gps point
              lat = results[0].geometry.location.lat().toPrecision(8)
              lon = results[0].geometry.location.lng().toPrecision(8)
              newMarker = new google.maps.Marker
                position: new google.maps.LatLng(lat, lon),
                map: @map,
                icon: stopMarker
              latlonEntry = new Entry name: "gps$#{lat},#{lon}", \
                  path: "#{entry.path}/gps$#{lat},#{lon}", address: entry.address, \
                  done: entry.done, type: entry.type, route: entry.route, \
                  number: entry.number
              @entries.addSubEntry latlonEntry, (->)

              # add file for the times
              times = (time.format('hhmm AM') for time in entry.times)
              timesEntry = new Entry name: "times$#{times.join(',')}", \
                  address: entry.address, done: entry.done, type: entry.type, \
                  route: entry.route, number: entry.number
              timesEntry.path = "#{entry.path}/#{timesEntry.name}"
              @entries.addSubEntry timesEntry, (->)

              # add file for the ETAs
              etasEntry = new Entry name: "etas$#{entry.etas.join(',')}", \
                  address: entry.address, done: entry.done, type: entry.type, \
                  route: entry.route, number: entry.number
              etasEntry.path = "#{entry.path}/#{etasEntry.name}"
              @entries.addSubEntry etasEntry, (->)
              
              # add file for the destTimes
              dests = (time.format('hhmm AM') for time in entry.dests)
              destsEntry = new Entry name: "dests$#{dests.join(',')}", \
                  address: entry.address, done: entry.done, type: entry.type, \
                  route: entry.route, number: entry.number
              destsEntry.path = "#{entry.path}/#{destsEntry.name}"
              @entries.addSubEntry destsEntry, (->)
              
            callback()
          else
            if @entries.find entry
              window.alert "You already have at #{entry.name} on your list!"
              callback()
            else if status == "OVER_QUERY_LIMIT"
              delay 500, =>
                @toAddEntry(entry, callback)
            else
              console.log "Error geocoding: " + status + " " + entry.name
              callback() )

  # Called when the user wants to create a new entry.
  onNewEntry: (event) ->
    event.preventDefault()
    if event.target.id == "new-entry-form"
      entries = (new Entry name: entry, done: false, 
                type: 'active' for entry in \
                $('#new-entry-name').val().split '\n')
    else if event.target.id == "new-addr-form"
      entries = (new Entry name: entry, done: false, type: 'addr' for entry in \
                $('#new-addr-name').val().split '\n')
    else if event.target.id == "new-bug-form"
      entries = (new Entry name: entry, done: false, type: 'bug' for entry in \
                $('#new-bug-name').val().split '\n')

    # entry = new Entry name: $('#new-entry-name').val(), done: false
    $("#new-#{entry.type}-button").attr 'disabled', 'disabled'
    $("#new-#{entry.type}-name").attr 'disabled', 'disabled'
    async.eachSeries entries, @toAddEntry, (err) ->
      if err
        console.log "ERROR adding addresses: " + err
      else
        $("#new-#{entry.type}-name").removeAttr('disabled').val ''
        $("#new-#{entry.type}-button").removeAttr 'disabled'
        console.log 'Done adding addresses'

  # Called when the user wants to create a new shuttle route.
  onNewRoute: (event) ->
    event.preventDefault()
    stops = $('#new-stop-name').val().split '\n'
    stopName = stops[0].trim()
    stops = stops[1..]
    if event.target.id == "new-stop-form"
      stops = (stop.replace(/\t/g,"$") for stop in stops)
      referencePoint = (new Time time for time in stops[stops.length-1].split('$')[2..])
      sub = (el1, el2) -> el1 - el2
      entries = (new Entry name: entry, type: 'stop', route: stopName, \
                address: entry.split('$',3)[1], done: false, \
                number: entry.split('$',3)[0] for entry in stops)
      for entry in entries
        entry.times = (new Time time for time in entry.name.split('$')[2..])
        entry.etas = zipWith sub, (point.nextDate() for point in referencePoint), \
                    (time.nextDate() for time in entry.times)
        entry.etas = ((if eta > 100000000 then null else eta/1000) for eta in entry.etas)
        entry.dests = referencePoint
    console.log entries
    # entry = new Entry name: $('#new-entry-name').val(), done: false
    $("#new-#{entry.type}-button").attr 'disabled', 'disabled'
    $("#new-#{entry.type}-name").attr 'disabled', 'disabled'
    async.eachSeries entries, @toAddRoute, (err) ->
      if err
        console.log "ERROR adding route: " + err
      else
        $("#new-#{entry.type}-name").removeAttr('disabled').val ''
        $("#new-#{entry.type}-button").removeAttr 'disabled'
        console.log 'Done adding route'

  # Called when the user wants to mark a entry as done.
  onGoToEntry: (event, entry) ->
    $entry = @$entryElement event.target
    $('button', $entry).attr 'disabled', 'disabled'
    @entries.setEntryDone entry, true, =>
      $entry.remove()
      @renderEntry entry

  # Called when the user wants to mark a entry as done.
  onDoneEntry: (event, entry) ->
    $entry = @$entryElement event.target
    $('button', $entry).attr 'disabled', 'disabled'
    @entries.setEntryDone entry, true, =>
      $entry.remove()
      @renderEntry entry

  # Called when the user wants to mark a entry as active.
  onActiveEntry: (event, entry) ->
    $entry = @$entryElement event.target
    $('button', $entry).attr 'disabled', 'disabled'
    @entries.setEntryDone entry, false, =>
      $entry.remove()
      @renderEntry entry

  # Called when the user wants to permanently remove a entry.
  onRemoveEntry: (event, entry) ->
    $entry = @$entryElement event.target
    $('button', $entry).attr 'disabled', 'disabled'
    @entries.removeEntry entry, ->
      $entry.remove()

  # Called when the user enters a search.
  onSearch: (event, entry) ->
    event.preventDefault()
    addr = $('#search-form-orig').val()
    console.log addr
    
    if addr == "purple"
      styles = [
        {
          stylers: [
            { hue: "#a375d1" },
            { saturation: -30 }
          ]
        },{
          featureType: "road",
          elementType: "geometry",
          stylers: [
            { lightness: 100 },
            { visibility: "simplified" }
          ]
        }
      ]
      @map.setOptions({styles: styles})
    else if addr == "blue"
      styles = [
        {
          stylers: [
            { hue: "#649cd1" },
            { saturation: -20 }
          ]
        },{
          featureType: "road",
          elementType: "geometry",
          stylers: [
            { lightness: 100 },
            { visibility: "simplified" }
          ]
        }
      ]
      @map.setOptions({styles: styles})
    else
      # geocode for lat lon
      geocoder = new google.maps.Geocoder()
      geocoder.geocode { 'address': addr}, (results, status) =>
        if (status == google.maps.GeocoderStatus.OK)
          lat = results[0].geometry.location.lat().toPrecision(8)
          lon = results[0].geometry.location.lng().toPrecision(8)
          name = results[0].formatted_address.replace('/',' or ')
          # create new entry with lat, lon, name
          entry = new Entry name: name, lat: lat, lon: lon
          @computeTransitTime entry, window.app.entries.stop, ->
            console.log "Search completed"
          console.log "Error SEARCH #{status}"

  # Called when the user wants to sign out of the application.
  onSignOut: (event, entry) ->
    @dbClient.signOut (error) =>
      return @showError(error) if error
      window.location.reload()

  # Finds the DOM element representing a entry.
  #
  # @param {DOMElement} element any element inside the entry element
  # @return {jQuery<DOMElement>} a jQuery wrapper around the DOM element
  #     representing a entry
  $entryElement: (element) ->
    $(element).closest 'li.entry'

  # Sets up listeners for the relevant DOM events.
  wire: ->
    $('#new-entry-form').submit (event) => @onNewEntry event
    $('#new-addr-form').submit (event) => @onNewEntry event
    $('#new-stop-form').submit (event) => @onNewRoute event
    $('#new-bug-form').submit (event) => @onNewEntry event
    $('#search-form').submit (event) => @onSearch event

  # Updates the UI to show that an error has occurred.
  showError: (error) ->
    $('#error-notice').removeClass 'hidden'
    console.log error if window.console

# Model that wraps all a user's entries.
class Entries
  # @param {Dashboard} controller the application controller
  constructor: (@controller) ->
    @dbClient = @controller.dbClient
    [@active, @done, @addr, @stop, @bug] = [[], [], [], {}, []]

  # Reads all the entries from a user's Dropbox.
  #
  # @param {function()} done called when all the entries are read from the user's
  #     Dropbox, and the active and done properties are set
  load: (done) ->
    # We read the done entries and the active entries in parallel. The variables
    # below tell us when we're done with both.
    readActive = readDone = readAddr = readStop = readBug = false

    @dbClient.mkdir 'shuttle-dashboard-js-data/active', (error, stat) =>
      # Issued mkdir so we always have a directory to read from.
      # In most cases, this will fail, so don't bother checking for errors.
      @dbClient.readdir 'shuttle-dashboard-js-data/active', (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        @active = (Entry.fromStat(stat) for stat in entry_stats)
        readActive = true
        done() if readActive and readDone and readAddr and readStop and readBug
    @dbClient.mkdir 'shuttle-dashboard-js-data/done', (error, stat) =>
      @dbClient.readdir 'shuttle-dashboard-js-data/done', (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        @done = (Entry.fromStat(stat) for stat in entry_stats)
        readDone = true
        done() if readActive and readDone and readAddr and readStop and readBug
    @dbClient.mkdir addrDir, (error, stat) =>
      # Issued mkdir so we always have a directory to read from.
      # In most cases, this will fail, so don't bother checking for errors.
      @dbClient.readdir addrDir, (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        @addr = (Entry.fromStat(stat) for stat in entry_stats)
        async.mapSeries @addr, @loadGPSDelay, (err, results) =>
          @addr = results
          console.log @addr
          readAddr = true
          done() if readActive and readDone and readAddr and readStop and readBug
    @dbClient.mkdir stopDir, (error, stat) =>
      # Issued mkdir so we always have a directory to read from.
      # In most cases, this will fail, so don't bother checking for errors.
      @dbClient.readdir stopDir, (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        async.eachSeries entry_stats, @loadRoutes, =>
          console.log @stop
          readStop = true
          done() if readActive and readDone and readAddr and readStop and readBug
    @dbClient.mkdir bugDir, (error, stat) =>
      # Issued mkdir so we always have a directory to read from.
      # In most cases, this will fail, so don't bother checking for errors.
      @dbClient.readdir bugDir, (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        @bug = (Entry.fromStat(stat) for stat in entry_stats)
        readBug = true
        done() if readActive and readDone and readAddr and readStop and readBug
    @

  loadGPSDelay: (entry, callback) =>
    delay 1, =>
      @dbClient.readdir entry.path, (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        if entry_stats.length == 0
          console.log "No GPS found for: #{entry_stats.path}"
        else
          gps = (Entry.fromStat(stat) for stat in entry_stats)[0]
          [lat,lon] = gps.name.split('$',2)[1].split(',',2)
          entry.setLatLon(lat,lon)
      callback(null,entry)

  loadRoutes: (route, callback) =>
    @dbClient.readdir route.path, (error, entries, dir_stat, entry_stats) =>
      return @showError(error) if error
      for stat in entry_stats
        entry = Entry.fromStat(stat)
        entry = @loadAttrs entry, ->
        if @stop[entry.route]
          @stop[entry.route].push entry
        else
          @stop[entry.route] = [entry]
      callback()

  loadAttrs: (entry, callback) =>
    @dbClient.readdir entry.path, (error, entries, dir_stat, entry_stats) =>
      return @showError(error) if error
      attrs = (Entry.fromStat(stat) for stat in entry_stats)
      for attr in attrs
        if attr.number == 'gps'
          [lat,lon] = attr.address.split(',',2)
          entry.setLatLon(lat,lon)
        else if attr.number == 'times'
          times = (new Time(time) for time in attr.address.split(','))
          entry.setTimes(times)
        else if attr.number == 'etas'
          etas = (eta for eta in attr.address.split(','))
          entry.setETAs(etas)
        else if attr.number == 'dests'
          dests = (new Time(dest) for dest in attr.address.split(','))
          entry.setDests(dests)
      callback()
    entry

  # Adds a new entry to the user's set of entries.
  #
  # @param {Entry} entry the entry to be added
  # @param {function()} done called when the entry is saved to the user's
  #     Dropbox
  addEntry: (entry, done) ->
    @dbClient.mkdir entry.path, '', (error, stat) =>
      return @showError(error) if error
      @addEntryToModel entry
      done()

  # Adds a new entry to the user's set of entries.
  #
  # @param {Entry} entry the entry to be added
  # @param {function()} done called when the entry is saved to the user's
  #     Dropbox
  addSubEntry: (entry, done) ->
    @dbClient.writeFile entry.path, '', (error, stat) =>
      return @showError(error) if error
      @addEntryToModel entry
      done()

  # Returns a entry with the given name, if it exists.
  #
  # @param {String} name the name to search for
  # @return {?Entry} entry the entry with the given name, or null if no such 
  # entry
  #     exists
  find: (entry) ->
    @typeMap = {'addr': {dir: addrDir, list: @addr}, \
               'stop': {dir: stopDir, list: @stop}, \
               'bug':  {dir: bugDir, list: @bug}, \
               '(none)':{dir: "#{rootDir}/active", list: @active} }

    for e in @typeMap[entry.type].list
      return e if e.name is entry.name
    null

  # Removes a entry from the list of entries.
  #
  # @param {Entry} entry the entry to be removed
  # @param {function()} done called when the entry is removed from the user's
  #     Dropbox
  removeEntry: (entry, done) ->
    @dbClient.remove entry.path(), (error, stat) =>
      return @showError(error) if error
      @removeEntryFromModel entry
      done()

  # Marks a active entry as done, or a done entry as active.
  #
  # @param {Entry} the entry to be changed
  setEntryGoTo: (entry, newDoneValue, done) ->
    [oldDoneValue, entry.done] = [entry.done, newDoneValue]
    newPath = entry.path()
    entry.done = oldDoneValue

    @dbClient.move entry.path(), newPath, (error, stat) =>
      return @showError(error) if error
      @removeEntryFromModel entry
      entry.done = newDoneValue
      @addEntryToModel entry
      done()

  # Marks a active entry as done, or a done entry as active.
  #
  # @param {Entry} the entry to be changed
  setEntryDone: (entry, newDoneValue, done) ->
    [oldDoneValue, entry.done] = [entry.done, newDoneValue]
    newPath = entry.path()
    entry.done = oldDoneValue

    @dbClient.move entry.path(), newPath, (error, stat) =>
      return @showError(error) if error
      @removeEntryFromModel entry
      entry.done = newDoneValue
      @addEntryToModel entry
      done()

  # Adds a entry to the in-memory model. Should not be called directly.
  addEntryToModel: (entry) ->
    @entryArray(entry).push entry

  # Remove a entry from the in-memory model. Should not be called directly.
  removeEntryFromModel: (entry) ->
    entryArray = @entryArray entry
    for _entry, index in entryArray
      if _entry is entry
        entryArray.splice index, 1
        break

  # @param {Entry} the entry whose containing array should be returned
  # @return {Array<Entry>} the array that should contain the given entry
  entryArray: (entry) ->
    if entry.done then @done else @active

  # Updates the UI to show that an error has occurred.
  showError: (error) ->
    @controller.showError error

# Model for a single user entry.
class Entry
  # Creates a entry with default values.
  constructor: (properties) ->
    @path = properties?.path or '(none)'
    @name = properties?.name or '(no name)'
    @done = properties?.done or false
    @type = properties?.type or '(none)'
    @route = properties?.route or '(none)'
    @number = properties?.number or '(none)'
    @address = properties?.address or '(none)'
    @lat = properties?.lat or '(none)'
    @lon = properties?.lon or '(none)'
    @times = properties?.times or '(none)'
    @etas = properties?.etas or '(none)'
    @dests = properties?.dests or '(none)'
    # English-only hack that removes slashes from the entry name.
    # @name = @name.replace(/\ \/\ /g, ' or ').replace(/\//g, ' or ')
    @typeMap = {'addr': {dir: addrDir}, \
               'stop': {dir: stopDir}, \
               'bug':  {dir: bugDir}, \
               '(none)':{dir: "#{rootDir}/active"} }

  # Creates a Entry from the stat of its file in a user's Dropbox.
  #
  # @param {Dropbox.File.Stat} entry the directory entry representing the entry
  # @return {Entry} the newly created entry
  @fromStat: (entry) ->
    if DIR2TYPE[entry.path.split('/',3)[2]] == 'stop'
      newEntry = new Entry done: entry.path.split('/', 3)[1] is 'done', \
               path: entry.path, \
               address: entry.name.split('$',2)[1], \
               type: DIR2TYPE[entry.path.split('/',3)[2]], \
               number: entry.name.split('$',2)[0], \ # label
               route: entry.path.split('/',4)[3]
      newEntry.name = "#{newEntry.route} #{newEntry.number} #{newEntry.address}"
      return newEntry
    else
      new Entry name: entry.name, done: entry.path.split('/', 3)[1] is 'done', \
               path: entry.path, \
               address: entry.name, \
               type: DIR2TYPE[entry.path.split('/',3)[2]]

  setLatLon: (lat,lon) =>
    @lat = lat
    @lon = lon
    @

  setTimes: (times) =>
    @times = times
    @

  setETAs: (etas) =>
    @etas = etas
    @

  setDests: (dests) =>
    @dests = dests
    @

  getPrevDelta: (time) =>
    deltas = (time.nextDate() - t.nextDate() for t in @dests when time.nextDate() >= t.nextDate())
    if not deltas
      console.log "Error computing PrevDelta: #{@name}"
      return null
    delta = Math.min.apply null, deltas 
    return delta

  getNextDelta: (time) =>
    deltas = (t.nextDate() - time.nextDate() for t in @times when t.nextDate() >= time.nextDate())
    if not deltas
      console.log "Error computing NextDelta: #{@name}"
      return null
    delta = Math.min.apply null, deltas 
    return delta

  # Get time of prev shuttle departure that arrives (at HQ)  before arg:time
  getPrevTime: (time) =>
    minDelta = @getPrevDelta(time)
    for t,i in @dests
      return @times[i] if minDelta == time.nextDate() - t.nextDate()

  # Get time of next shuttle departure after arg:time
  getNextTime: (time) =>
    minDelta = @getNextDelta(time)
    for t in @times
      return t if minDelta == t.nextDate() - time.nextDate()

  # Get time of prev shuttle arrival (at HQ)  before arg:time
  getPrevDest: (time) =>
    minDelta = @getPrevDelta(time)
    for t in @dests
      return t if minDelta == time.nextDate() - t.nextDate()

  # Get time of next shuttle arrival (at HQ) that departs after arg:time
  getNextDest: (time) =>
    minDelta = @getNextDelta(time)
    for t,i in @times
      return @dests[i] if minDelta == t.nextDate() - time.nextDate()

  # Path to the file representing the entry in the user's Dropbox.
  # @return {String} fully-qualified path
  path: ->
    "#{@typeMap[@type].dir}/#{@name}"

# Main
# ------------------------------------------------------------------------------

# Start up the code when the DOM is fully loaded.
$ ->
  client = new Dropbox.Client key: 'vry9x4wyov1mkyo'
  window.app = new Dashboard client, '#app-ui'
  console.log('dashboard loaded')
