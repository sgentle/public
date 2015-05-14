v = cp.v

raf = window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  window.setTimeout(cb, 1000/60)


context = undefined
soundSource = undefined
soundBuffer = undefined
url = "/amen.mp3"



Query = ->
  @space = space = new cp.Space()
  @remainder = 0
  @fps = 0
  @simulationTime = 0
  @drawTime = 0
  @mouse = v(0, 0)

  canvas = document.querySelector('canvas')
  @ctx = canvas.getContext('2d')
  space.iterations = 5

  width = @width = canvas.width
  height = @height = canvas.height
  if width / height > 640 / 480
    @scale = height / 480
  else
    @scale = width / 640

  canvas2point = @canvas2point = (x, y) =>
    v(x / @scale, 480 - y / @scale)

  @point2canvas = (point) =>
    v(point.x * @scale, (480 - point.y) * @scale)

  canvas.onmousemove = (e) =>
    @mouse = canvas2point(e.clientX - canvas.offsetLeft, e.clientY - canvas.offsetTop)

  # add a fat segment
  mass = 10
  length = 100
  a = v(-length / 2, 0)
  b = v(length / 2, 0)
  body = space.addBody(new cp.Body(mass, cp.momentForSegment(mass, a, b)))
  body.setPos v(320, 340)
  space.addShape new cp.SegmentShape(body, a, b, 20)

  # add a fat segment
  for x in [0..3]
    mass = 5
    length = 100
    a = v(-length / 2, 0)
    b = v(length / 2, 0)
    body = space.addBody(new cp.Body(mass, cp.momentForSegment(mass, a, b)))
    body.setPos v(10 + x * 110, 300)
    space.addShape new cp.SegmentShape(body, v(-100, 0), v(0, 0), 2)
    body = space.addBody(new cp.Body(mass, cp.momentForSegment(mass, a, b)))
    body.setPos v(10 + x * 110, 300)
    space.addShape new cp.SegmentShape(body, v(0, -100), v(0, 0), 2)
    body = space.addBody(new cp.Body(mass, cp.momentForSegment(mass, a, b)))
    body.setPos v(10 + x * 110, 300)
    space.addShape new cp.SegmentShape(body, v(-100, -100), v(-100, 0), 2)

  # add a static segment
  space.addShape new cp.SegmentShape(space.staticBody, v(320, 540), v(620, 240), 0)

  # add a pentagon
  mass = 1
  NUM_VERTS = 5
  verts = new Array(NUM_VERTS * 2)
  i = 0

  while i < NUM_VERTS * 2
    angle = -Math.PI * i / NUM_VERTS
    verts[i] = 30 * Math.cos(angle)
    verts[i + 1] = 30 * Math.sin(angle)
    i += 2

  body = space.addBody(new cp.Body(mass, cp.momentForPoly(mass, verts, v(0, 0))))
  body.setPos v(350 + 60, 220 + 60)
  space.addShape new cp.PolyShape(body, verts, v(0, 0))
  # add a circle
  mass = 1

  r = 20
  body = space.addBody(new cp.Body(mass, cp.momentForCircle(mass, 0, r, v(0, 0))))
  body.setPos v(320 + 100, 240 + 120)
  space.addShape new cp.CircleShape(body, r, v(0, 0))
  @drawSegment = (start, end, style) ->
    ctx = @ctx
    ctx.beginPath()
    startT = @point2canvas(start)
    endT = @point2canvas(end)
    ctx.moveTo startT.x, startT.y
    ctx.lineTo endT.x, endT.y
    ctx.lineWidth = 1
    ctx.strokeStyle = style
    ctx.stroke()

  @drawBB = (bb, fillStyle, strokeStyle) ->
    ctx = @ctx
    p = @point2canvas(v(bb.l, bb.t))
    width = @scale * (bb.r - bb.l)
    height = @scale * (bb.t - bb.b)
    if fillStyle
      ctx.fillStyle = fillStyle
      ctx.fillRect p.x, p.y, width, height
    if strokeStyle
      ctx.strokeStyle = strokeStyle
      ctx.strokeRect p.x, p.y, width, height

  this

Query::drawInfo = ->
  space = @space
  maxWidth = @width - 20
  @ctx.textAlign = "start"
  @ctx.textBaseline = "alphabetic"
  @ctx.fillStyle = "black"
  
  #this.ctx.fillText(this.ctx.font, 100, 100);
  fpsStr = Math.floor(@fps * 10) / 10
  fpsStr = "--"  if space.activeShapes.count is 0
  @ctx.fillText "FPS: " + fpsStr, 10, 50, maxWidth
  @ctx.fillText "Step: " + space.stamp, 10, 80, maxWidth
  arbiters = space.arbiters.length
  @maxArbiters = (if @maxArbiters then Math.max(@maxArbiters, arbiters) else arbiters)
  @ctx.fillText "Arbiters: " + arbiters + " (Max: " + @maxArbiters + ")", 10, 110, maxWidth
  contacts = 0
  i = 0

  while i < arbiters
    contacts += space.arbiters[i].contacts.length
    i++
  @maxContacts = (if @maxContacts then Math.max(@maxContacts, contacts) else contacts)
  @ctx.fillText "Contact points: " + contacts + " (Max: " + @maxContacts + ")", 10, 140, maxWidth
  @ctx.fillText "Simulation time: " + @simulationTime + " ms", 10, 170, maxWidth
  @ctx.fillText "Draw time: " + @drawTime + " ms", 10, 200, maxWidth
  @ctx.fillText @message, 10, @height - 50, maxWidth  if @message

Query::drawInfo = ->
  maxWidth = @width - 20
  @ctx.textAlign = "start"
  @ctx.textBaseline = "alphabetic"
  @ctx.fillStyle = "black"
  @ctx.fillText @message, 10, @height - 50, maxWidth  if @message

Query::draw = ->
  self = this
  ctx = @ctx

  # Draw shapes
  ctx.strokeStyle = 'black'
  ctx.clearRect(0, 0, this.width, this.height)

  this.ctx.font = "16px sans-serif"
  this.ctx.lineCap = 'round'
  
  this.space.eachShape (shape) ->
    ctx.fillStyle = shape.style()
    shape.draw(ctx, self.scale, self.point2canvas)
  
  start = v(320, 240)
  end = @mouse

  SOUNDSCALE = 0.01

  # Draw a green line from start to end.
  @drawSegment start, end, "green"
  @message = "Query: Dist(" + Math.floor(v.dist(start, end)) + ") Point " + v.str(end) + ", "

  collisionscale = 1
  intersections = 0
  result = @space.segmentQuery start, end, cp.ALL_LAYERS, cp.NO_GROUP, (shape, vect, a, b, c) =>
    intersections++
    info = shape.segmentQuery(start, end)
    point = info.hitPoint(start, end)
    
    # Draw red over the occluded part of the query
    @drawSegment point, end, "red"
    
    # Draw a little blue surface normal
    @drawSegment point, v.add(point, v.mult(info.n, 16)), "blue"
    collisionscale *= (Math.log(shape.body.m+1))*3
    
    # Draw a little red dot on the hit point.
    #ChipmunkDebugDrawPoints(3, 1, &point, RGBAColor(1,0,0,1));
    #@message += "Segment Query: Dist(" + Math.floor(info.hitDist(start, end)) + ") Normal " + v.str(info.n)
  collisionscale = 9999999 unless isFinite collisionscale
  @message += " Intersections: #{intersections},"
  @message += " Collision Scale: #{collisionscale}"
  context?.panner?.setPosition end.x*SOUNDSCALE*collisionscale, end.y*SOUNDSCALE*collisionscale, 0
  context?.listener?.setPosition start.x*SOUNDSCALE*collisionscale, start.y*SOUNDSCALE*collisionscale, 0
  
  #info = @space.segmentQueryFirst start, end, cp.ALL_LAYERS, cp.NO_GROUP
  #if info
  #  console.log "segment hit", info
  #  point = info.hitPoint(start, end)
  #  
  #  # Draw red over the occluded part of the query
  #  @drawSegment point, end, "red"
  #  
  #  # Draw a little blue surface normal
  #  @drawSegment point, v.add(point, v.mult(info.n, 16)), "blue"
  #  
  #  # Draw a little red dot on the hit point.
  #  #ChipmunkDebugDrawPoints(3, 1, &point, RGBAColor(1,0,0,1));
  #  @message += "Segment Query: Dist(" + Math.floor(info.hitDist(start, end)) + ") Normal " + v.str(info.n)
  
  #messageCursor += sprintf(messageCursor, "Segment Query: Dist(%f) Normal%s", cpSegmentQueryHitDist(start, end, info), cpvstr(info.n))
  #else
  #  @message += "Segment Query: (None)"
  #nearestInfo = @space.nearestPointQueryNearest(v(0,0), 100, cp.ALL_LAYERS, cp.NO_GROUP)
  #if nearestInfo
  #  @drawSegment @mouse, nearestInfo.p, "grey"
  #  
  #  # Draw a red bounding box around the shape under the mouse.
  #  @drawBB nearestInfo.shape.getBB(), null, "red"  if nearestInfo.d < 0
  @drawInfo()

Query::update = ->

Query::run = ->
  this.running = true

  self = this

  lastTime = 0
  step = (time) ->
    self.step(time - lastTime)
    lastTime = time

    if (self.running)
      raf(step)

  step(0)

Query::stop = ->
  @running = false

Query::step = (dt) ->
  # Update FPS
  @fps = 0.9 * @fps + 0.1 * (1000 / dt)  if dt > 0
  
  # Move mouse body toward the mouse
  # newPoint = v.lerp(@mouseBody.p, @mouse, 0.25)
  # @mouseBody.v = v.mult(v.sub(newPoint, @mouseBody.p), 60)
  # @mouseBody.p = newPoint
  lastNumActiveShapes = @space.activeShapes.count
  now = Date.now()
  @update 1 / 60
  @simulationTime += Date.now() - now
  
  # Only redraw if the simulation isn't asleep.
  if lastNumActiveShapes > 0 #or Demo.resized
    now = Date.now()
    @draw()
    @drawTime += Date.now() - now
    #Demo.resized = false


# Step 1 - Initialise the Audio Context
# There can be only one!
init = ->
  if typeof AudioContext isnt "undefined"
    context = new AudioContext()
  else if typeof webkitAudioContext isnt "undefined"
    context = new webkitAudioContext()
  else
    throw new Error("AudioContext not supported. :(")

# Step 2: Load our Sound using XHR
startSound = ->
  
  # Note: this loads asynchronously
  request = new XMLHttpRequest()
  request.open "GET", url, true
  request.responseType = "arraybuffer"
  
  # Our asynchronous callback
  request.onload = ->
    audioData = request.response
    audioGraph audioData

  request.send()

# Finally: tell the source when to start
playSound = ->
  
  # play the source now
  soundSource.start context.currentTime

stopSound = ->
  
  # stop the source now
  soundSource.stop context.currentTime

# Events for the play/stop bottons

# This is the code we are interested in
audioGraph = (audioData) ->
  panner = undefined
  
  # Same setup as before
  soundSource = context.createBufferSource()
  soundSource.loop = true
  context.decodeAudioData audioData, (soundBuffer) ->
    soundSource.buffer = soundBuffer

    panner = context.createPanner()
    panner.panningModel = "HRTF"
    window.panner = panner
    context.panner = panner
    panner.setPosition 20, -5, 0
    soundSource.connect panner
    panner.connect context.destination
    
    # Each context has a single 'Listener' 
    context.listener.setPosition 10, 0, 0
    
    # Finally
    playSound soundSource

init()
startSound()




window.Query = Query
