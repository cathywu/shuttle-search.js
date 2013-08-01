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
stopMarker = 'images/stop.png'
addrMarker = 'images/house.png'

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
 stop: new google.maps.MarkerImage(
  stopMarker,
  new google.maps.Size( 16, 16 ),
  new google.maps.Point( 0, 0 ),
  new google.maps.Point( 8, 16 )
 )
}

# Aliases
# ------------------------------------------------------------------------------
delay = (ms, func) -> setTimeout func, ms

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
    @$activeList = $ '#active-entry-list', @$root
    @$doneList = $ '#done-entry-list', @$root
    @$addrList = $ '#addr-entry-list', @$root
    @$stopList = $ '#stop-entry-list', @$root
    @$bugList = $ '#bug-entry-list', @$root

    # Google Maps
    center = new google.maps.LatLng(37.776019, -122.393085)
    @map = @createGoogleMap(center)
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
        if @entries.addr.length > 0
          async.eachSeries @entries.addr, @plotAddr, =>
            @mapRefresh center
            console.log 'Done plotting addresses'
        # for route,stops of @entries.stop
        #   if stops.length > 0
        #     async.eachSeries stops, @plotStop, =>
        #       @mapRefresh center
        #       console.log "Done plotting #{route} stops"
        routes = (stops for route,stops of @entries.stop)
        async.eachSeries routes, @plotRoute, =>
          console.log "Done plotting shuttle routes"
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
      zoom: 12
      streetViewControl: false
      panControl: false

    styles = [
      {
        stylers: [
          { hue: "#00ffe6" },
          { saturation: -20 }
        ]
      },{
        featureType: "road",
        elementType: "geometry",
        stylers: [
          { lightness: 100 },
          { visibility: "simplified" }
        ]
      # },{
      #   featureType: "road",
      #   elementType: "labels",
      #   stylers: [
      #     { visibility: "off" }
      #   ]
      }
    ]
    
    map.setOptions({styles: styles})

    return map

  mapRefresh: (center) =>
    google.maps.event.trigger( @map, 'resize' )
    @map.setCenter(center)

  # FIXME @plotLatLons function not accessible?
  plotLatLons: (map, marker, latlons) ->
    for latlon in latlons
      beachMarker = new google.maps.Marker
        position: latlon,
        map: map,
        icon: marker
  
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
        plotLatLons(map, marker, latlons)
        google.maps.event.trigger( map, 'resize' ) )\
      for addr in addrs)

  plot: (lat, lon, marker, label, delayTime, callback) =>
    delay delayTime, =>
      newMarker = new google.maps.Marker
        position: new google.maps.LatLng(lat, lon)
        map: @map
        icon: marker
        title: label
      callback()

  plotAddr: (entry, callback) =>
    marker = addrMarker
    label = entry.name
    delayTime = 5
    @plot(entry.lat, entry.lon, marker, label, delayTime, callback)

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

  makeMarker: (position, icon, title) =>
   new google.maps.Marker
     position: position,
     map: @map,
     icon: icon,
     title: title

  plotRoute: (stops, callback) =>
    console.log stops
    rendererOptions = {
      map: @map,
      suppressMarkers: true
      }
    directionsDisplay = new google.maps.DirectionsRenderer(rendererOptions)
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
        console.log response
        directionsDisplay.setDirections(response)
        leg = response.routes[0].legs[0]
        console.log leg.end_location
        for leg,i in response.routes[0].legs
          ind = (i-1+stops.length) % stops.length
          label = "#{stops[ind].route} - Stop #{stops[ind].name.split('$',2)[0]} - #{stops[ind].name.split('$',2)[1]} || Next stop: #{leg.duration.text} (#{leg.distance.text})"
          @makeMarker leg.start_location, icons.stop, label
      else
        alert ('failed to get directions')
    callback()

  #
  # RENDER FUNCTIONS
  # ----------------------------------------------------------------------------

  # Re-renders all the data.
  render: ->
    @$activeList.empty()
    @$doneList.empty()
    @$addrList.empty()
    @$stopList.empty()
    @$bugList.empty()
    for entries in [@entries.active, @entries.done, @entries.addr, @entries.stop, @entries.bug]
        @renderEntry(entry) for entry in entries
    @

  # Renders a entry into the list that it belongs to.
  renderEntry: (entry) ->
    $list = @typeMap[entry.type].list
    # $list = if entry.done then @$doneList else @$activeList
    $list.append @$entryDom(entry)

  # Renders the list element representing a entry.
  #
  # @param {Entry} entry the entry to be rendered
  # @return {jQuery<li>} jQuery wrapper for the DOM representing the entry
  $entryDom: (entry) ->
    $entry = $ @entryTemplate
    $('.entry-name', $entry).text entry.name
    $('.entry-remove-button', $entry).click (event) => @onRemoveEntry event, entry
    if entry.done
      $('.entry-done-button', $entry).addClass 'hidden'
      $('.entry-active-button', $entry).click (event) =>
        @onActiveEntry event, entry
    else
      $('.entry-active-button', $entry).addClass 'hidden'
      $('.entry-done-button', $entry).click (event) => @onDoneEntry event, entry
    $entry

  # Entry render wrapper 
  toRender: (entry) ->
    =>
      @renderEntry entry

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
            entry.name = results[0].formatted_address
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
        geocoder.geocode( { 'address': entry.name}, (results, status) =>
          if (status == google.maps.GeocoderStatus.OK)
            entry.name = "#{entry.route}/#{entry.number}$#{results[0].formatted_address}"
            if @entries.find entry
              console.log "You already have at #{entry.name} on your list!"
            else
              @entries.addEntry entry, @toRender entry
              lat = results[0].geometry.location.lat().toPrecision(8)
              lon = results[0].geometry.location.lng().toPrecision(8)
              newMarker = new google.maps.Marker
                position: new google.maps.LatLng(lat, lon),
                map: @map,
                icon: stopMarker
              latlonEntry = new Entry name: "#{entry.name}/gps$#{lat},#{lon}", \
                  done: false, type: 'stop', route: entry.route, \
                  number: entry.number
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
      stop.replace("\t","$") for stop in stops
      entries = (new Entry name: entry, done: false, type: 'stop', \
                route: stopName, number: entry.split('\t',2)[0] for entry in stops)
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

  loadRoutes: (route, callback) =>
    @dbClient.readdir route.path, (error, entries, dir_stat, entry_stats) =>
      return @showError(error) if error
      for stat in entry_stats
        entry = Entry.fromStat(stat)
        entry = @loadGPS entry, ->
        if @stop[entry.route]
          @stop[entry.route].push entry
        else
          @stop[entry.route] = [entry]
      callback()

  loadGPSDelay: (entry, callback) =>
    delay 1, =>
      @dbClient.readdir entry.path, (error, entries, dir_stat, entry_stats) =>
        return @showError(error) if error
        if entry_stats.length == 0
          console.log "No GPS found for: #{entry_stats.path}"
        else
          gps = (Entry.fromStat(stat) for stat in entry_stats)[0]
          [lat,lon] = gps.name.split('$')[1].split(',')
          entry.setLatLon(lat,lon)
      callback(null,entry)

  loadGPS: (entry, callback) =>
    @dbClient.readdir entry.path, (error, entries, dir_stat, entry_stats) =>
      return @showError(error) if error
      if entry_stats.length == 0
        console.log "No GPS found for: #{entry_stats.path}"
      else
        gps = (Entry.fromStat(stat) for stat in entry_stats)[0]
        [lat,lon] = gps.name.split('$')[1].split(',')
        entry.setLatLon(lat,lon)
      callback()
    entry

  # Adds a new entry to the user's set of entries.
  #
  # @param {Entry} entry the entry to be added
  # @param {function()} done called when the entry is saved to the user's
  #     Dropbox
  addEntry: (entry, done) ->
    @dbClient.mkdir entry.path(), '', (error, stat) =>
      return @showError(error) if error
      @addEntryToModel entry
      done()

  # Adds a new entry to the user's set of entries.
  #
  # @param {Entry} entry the entry to be added
  # @param {function()} done called when the entry is saved to the user's
  #     Dropbox
  addSubEntry: (entry, done) ->
    @dbClient.writeFile entry.path(), '', (error, stat) =>
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
      new Entry name: entry.name, done: entry.path.split('/', 3)[1] is 'done', \
               path: entry.path, \
               address: entry.name.split('$',2)[1], \
               type: DIR2TYPE[entry.path.split('/',3)[2]], \
               number: entry.path.split('/',5)[4].split('$',2)[0], \
               route: entry.path.split('/',4)[3]
    else
      new Entry name: entry.name, done: entry.path.split('/', 3)[1] is 'done', \
               path: entry.path, \
               address: entry.name, \
               type: DIR2TYPE[entry.path.split('/',3)[2]]

  setLatLon: (lat,lon) =>
    @lat = lat
    @lon = lon
    @

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
