Activities = new Meteor.Collection('Activities')

[ARROW_LEFT, ARROW_RIGHT, ARROW_UP, ARROW_DOWN] = [ 37, 39, 38, 40 ]
CMD_KEY = 91
SHIFT_KEY = 16
CTRL_KEY = 17
OPT_KEY = 18
ENTER_KEY = 13
BACKSPACE_KEY = 8

getCursorPosition = () ->
  sel = window.getSelection()
  if not sel?
    return null
  if sel.rangeCount > 0
    range = sel.getRangeAt(0)
    {start: range.startOffset, end: range.endOffset}

trim = (str) ->
  str.replace(/^\s*/, '').replace(/\s*$/, '')

if Meteor.is_client

  Template.debug_info.cursorStart = ->
    cursor = Session.get('cursorAt')
    if cursor
      cursor.end

  Template.debug_info.cursorEnd = ->
    cursor = Session.get('cursorAt')
    if cursor
      cursor.start

  Template.input.prompt = ->
    (new Date()).toLocaleDateString()

  Template.input.activities = ->
    Activities.find {}, sort: {display_order: 1}

  updateEditTimeout = null
  modDown = false
  Template.activity_info.events
    'focus': (ev) ->
      console.log 'focus'
      Session.set 'focused', this._id
      cursor = getCursorPosition()
      if cursor?
        Session.set 'cursorAt', cursor
    'blur': (ev) ->
      console.log 'blur'
      Session.set 'focused', ''
    'keydown': (ev) ->
      node = ev.target
      if ev.which in [ENTER_KEY, ARROW_UP, ARROW_DOWN]
        ev.preventDefault()
      if ev.which in [CMD_KEY, SHIFT_KEY, CTRL_KEY, OPT_KEY]
        modDown = true
    'keyup': (ev) ->
      console.log ev.which
      console.log 'meta, alt, ctrl', ev.metaKey, ev.altKey, ev.ctrlKey
      node = ev.target
      if ev.which == ENTER_KEY
        new_display_order = this.display_order + 1
        if ev.shiftKey
          new_display_order = this.display_order
        Activities.update {display_order: {$gte: new_display_order}}, {$inc: {display_order: 1}}
        newId = Activities.insert rawString: ' ', display_order: new_display_order
        Session.set 'focused', newId
      else if ev.which in [ARROW_LEFT, ARROW_RIGHT]
        Session.set 'cursorAt', getCursorPosition()
      else if ev.which == ARROW_UP
        $(node).prev().focus()
      else if ev.which == ARROW_DOWN
        $(node).next().focus()
      else if ev.which in [CMD_KEY, SHIFT_KEY, CTRL_KEY, OPT_KEY]
        Session.set 'cursorAt', getCursorPosition()
        modDown = false
      else if not modDown
        if ev.which == BACKSPACE_KEY and this.rawString.length == 0
          Activities.update {display_order: {$gt: this.display_order}}, {$inc: {display_order: -1}}
          Activities.remove this._id
          $(node).prev().focus()
        else
          Session.set 'cursorAt', getCursorPosition()
          Activities.update this._id, $set: {rawString: trim($(node).text())}

  Template.activity_info.rendered = ->
    if this.data._id == Session.get 'focused'
      $(this.firstNode).focus()
      cursor = Session.get 'cursorAt'
      range = document.createRange()
      range.setStart this.firstNode.firstChild, cursor.start
      range.setEnd this.firstNode.firstChild, cursor.end
      range.collapse true
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range


if Meteor.is_server
  Meteor.startup ->
    # code to run on server at startup
