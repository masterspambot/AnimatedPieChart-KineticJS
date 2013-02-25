##################################################
## Preloader class
##################################################
'use strict'
class Preloader
  _interval = null

  constructor: (layer) ->
    @layer = layer

    # The preloader will be put into container for easier maipulation
    @container = new Kinetic.Container({
      height    : 50
      width     : 90
      x         : @layer.getWidth() / 2 - 45
      y         : @layer.getHeight() / 2 - 20
    })

  initialize: ->
    for i in [0...3]
      # Draw rectangles
      rect = new Kinetic.Rect({
        height  : 10
        width   : 10
        fill    : 'white'
        x       : i * 25
        y       : @container.getHeight() / 2 - 5
        offset  : {x:5, y:5}
      })

      # Add animation to rectangles
      @animate(rect, i)
      @container.add(rect)

    # Add some simple preloader text
    text = new Kinetic.Text({
      text: 'Loading the data...'
      fill: '#4d7a93'
      fontSize: 10
      fontStyle: 'bold'
      fontFamily: 'Arial'
      x: -15
      y: 32
      align: 'center'
    })
    @container.add(text)
    return @

  # Javascript maintains only one Interval per clousure
  # so that animate has to be fired for each object
  animate: (elem, i) ->
    _interval = setInterval( ->
      setTimeout( ->
        elem.transitionTo({
        scale: {
          x: if i==1 then 1.8 else 1.3,
          y: if i==1 then 1.8 else 1.3}
        duration: 0.3
        callback: ->
          elem.transitionTo({
          scale: {x:1, y:1}
          duration: 0.3
          })
        })
      , i*300)
    , 1200)

  addToStage: ->
    @layer.add(@container)
    return @

  removeFromStage: ->
    clearInterval(_interval)

    # After animation we call callback
    # to fire the removal of container
    @container.transitionTo({
      opacity: 0
      duration: 0.7
      callback: =>
        @layer.remove(@container)
    })
    return @

##################################################
## Cell class
##################################################
class Cell
  # Some constants to easier manipulate data
  _cellHeight = 20
  _cellWidth = 200
  _offsetTop = 85

  constructor: (@index,@desc, @arc, @startArc, @layer) ->
    @cellContainer = new Kinetic.Container()

  initialize: ->
    that = @
    # Cell background
    @cell = new Kinetic.Rect({
      width: _cellWidth
      height: _cellHeight
      fill :  if @index%2 then 'rgba(255,255,255,0.5)' else 'rgba(255,255,255,0.7)'
      x: 50
      y: @index*(_cellHeight+2) + _offsetTop
    })

    # Simple decor on the left
    # colored the same as pie
    @cellDecor = new Kinetic.Rect({
      width: 10
      height: _cellHeight
      fill :  'hsl(' + (100 *that.arc) + ',100%,57%)'
      opacity: 0.6
      x: 50
      y: @index*(_cellHeight+2)+ _offsetTop
    })

    # Text of the cell
    @cellText = new Kinetic.Text({
      text: that.desc
      fontSize: 10
      fill: '#033a59'
      fontStyle: 'bold'
      fontFamily: 'Arial'
      offset: [10,5]
      x: 80
      y: @index*(_cellHeight+2) + _offsetTop + _cellHeight/2
    })

    # Polyline connecting cell with pie
    @cellLine = new Kinetic.Line({
      # Array of points stored in x,y pairs
      points: [
        # Draw stright line 50px
        _cellWidth+50, @index*(_cellHeight+2) + _offsetTop + _cellHeight/2,
        _cellWidth+100, @index*(_cellHeight+2) + _offsetTop + _cellHeight/2
        # Angeled line
        _cellWidth+150, Math.sin(that.startArc+that.arc / 2)*140 + (that.layer.getHeight() / 2)
        # Taget ceneter of pie
        Math.cos(that.startArc+that.arc / 2)*140 + (that.layer.getWidth() / 2) + 130, Math.sin(that.startArc+that.arc / 2)*140 + (that.layer.getHeight() / 2)
      ]
      opacity: 0
      stroke: '#fff'
      strokeWidth: 2
    })

    # Simple circle decor on the center of
    # pie and end of polyline
    @lineDecor = new Kinetic.Circle({
      fill :  '#fff'
      radius: 6
      opacity: 0
      x: Math.cos(that.startArc+that.arc / 2)*140 + (that.layer.getWidth() / 2) + 130
      y: Math.sin(that.startArc+that.arc / 2)*140 + (that.layer.getHeight() / 2)
    })

    @cellContainer.add(@cell)
    @cellContainer.add(@cellDecor)
    @cellContainer.add(@cellText)

    # Its important to add them to chartLayer over everything else
    @layer.add(@cellLine)
    @layer.add(@lineDecor)
    return @

  addToStage: ->
    @layer.add(@cellContainer)

    @cellContainer.on('mouseenter', =>
      # Set cursor to hand
      document.body.style.cursor = "pointer"
      # Fade in decors and line connector
      @cellDecor.transitionTo({
        duration: 0.1
        opacity: 1
      })
      @cellLine.transitionTo({
        duration: 0.1
        opacity: 1
      })
      @lineDecor.transitionTo({
        duration: 0.1
        opacity: 1
      })
      # Find label container by name and fade it in
      labelContainer = @layer.getStage().get('.label_'+@index)
      labelContainer.apply('transitionTo',{
        duration: 0.2
        opacity: 1
      })
      # Find pie container by name, fade in and scale it to stand out
      pieContainer = @layer.getStage().get('.pie_'+@index)
      pieContainer.apply('transitionTo',{
        scale: {x: 1.25, y: 1.25}
        duration: 0.4
        opacity: 1
        easing: 'ease-out'
      })
    )

    @cellContainer.on('mouseleave', =>
      # Restore cursor to default
      document.body.style.cursor = "default"
      # Fade out decors and polyline and pie label
      @cellDecor.transitionTo({
        duration: 0.1
        opacity: 0.6
      })
      @cellLine.transitionTo({
        duration: 0.1
        opacity: 0
      })
      @lineDecor.transitionTo({
        duration: 0.1
        opacity: 0
      })
      labelContainer = @layer.getStage().get('.label_'+@index)
      labelContainer.apply('transitionTo',{
        duration: 0.2
        opacity: 0
      })
      # Return pie to its original size and opacity
      pieContainer = @layer.getStage().get('.pie_'+@index)
      pieContainer.apply('transitionTo',{
        scale: {x: 1, y: 1}
        duration: 0.2
        opacity: 0.8
        easing: 'ease-out'
      })
    )
    return @

##################################################
## Slice class
##################################################
class Pie
  constructor: (@index, @arc, @startArc, @radius, @layer) ->
    # Our pie container positioning the rotation point
    # on center of the pie chart
    @pieContainer = new Kinetic.Container({
      x: @layer.getWidth() / 2 + 130
      y: @layer.getHeight() / 2
      opacity: 0.8
      rotation: @startArc
      name: 'pie_'+@index
    })
    # Separate label container that doesnt
    # mess with rotation props
    @labelContainer = new Kinetic.Container({
      opacity: 0
      name: 'label_'+@index
    })

  initialize: ->
    that = @
    # Create pie shape by drawing simple custom shape
    # using canvas syntax
    pie = new Kinetic.Shape({
      drawFunc: (canvas) ->
        context = canvas.getContext('2d')
        context.beginPath()
        context.arc(0, 0 ,that.radius, 0, that.arc + 0.003)
        context.lineTo(0, 0)
        context.closePath()
        canvas.fillStroke(@)
      # Color it by value (green<->red)
      fill : 'hsl(' + (100 *that.arc) + ',100%,57%)'
    })
    @pieContainer.add(pie)

    # Percentage data label
    @label = new Kinetic.Text({
      text: parseFloat((that.arc / (2*Math.PI))*100).toFixed(1)+'%'
      fontSize: 11
      fill: '"#033a59"'
      fontStyle: 'bold'
      fontFamily: 'Arial'
      offset: [10,5]
      x: Math.cos(that.startArc+that.arc / 2)*280 + (that.layer.getWidth() / 2) + 130
      y: Math.sin(that.startArc+that.arc / 2)*280 + (that.layer.getHeight() / 2)
    })

    # Label will be put into small cicle next to pie
    @labelCircle = new Kinetic.Circle({
      radius: 20
      fill : 'rgba(255,255,255,0.6)'
      offset: [-2,0]
      x: Math.cos(that.startArc+that.arc / 2)*280 + (that.layer.getWidth() / 2) + 130
      y: Math.sin(that.startArc+that.arc / 2)*280 + (that.layer.getHeight() / 2)
    })

    @labelContainer.add(@labelCircle)
    @labelContainer.add(@label)
    return @

  addToStage: ->
    @layer.add(@pieContainer)
    @layer.add(@labelContainer)
    return @

##################################################
## Chart class
##################################################
class Chart
  _startArc = 0

  constructor: (containerId, height, width) ->
    @stage = new Kinetic.Stage({
      container : containerId
      height    : height
      width     : width
    })

    # Init the preloader layer
    @preloaderLayer = new Kinetic.Layer({
      height    : height
      width     : width
    })

    # Init the chart layer
    @chartLayer = new Kinetic.Layer({
      height    : height
      width     : width
      opacity   : 0
    })

    # Init preloader
    @preloader = new Preloader(@preloaderLayer).initialize().addToStage()
    @stage.add(@preloaderLayer)

  # Download JSON data via AJAX
  loadData: (url) =>
    $.ajax({
      url: url,
      dataType: 'json',
      cache: true
    }).complete( (data) => @parseData(data.responseText))

  # Parse downloaded HTML to extract the data
  parseData: (data) =>
    items = JSON.parse(data)
    for item, index in items.items
      new Pie(index, item.value, _startArc, 3/9*@stage.getHeight(), @chartLayer)
        .initialize()
        .addToStage()
      new Cell(index,item.desc, item.value, _startArc, @chartLayer)
        .initialize()
        .addToStage()
      _startArc += item.value

    @preloader.removeFromStage()
    @stage.add(@chartLayer)
    @chartLayer.transitionTo({
      opacity: 1
      duration: 0.7
    })

$( ->
  new Chart('chart', 600, 900).loadData('json/data.json')
)