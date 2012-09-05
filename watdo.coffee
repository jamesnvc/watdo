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
  str.replace(/^\s*/, '').replace(/\s+$/, ' ')

typeRegexes =
  "^[0-9]{4}$": 'year'
  "^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-zA-Z]+$": 'month'
  "^[0-9]{2}$": 'day'
  "^([0-9\.]+)([a-zA-Z]*) ([a-zA-Z -]+)$": 'food'
  "^([0-9]+)x([0-9]+)x([0-9]+) ([a-zA-Z]+)$": 'exercise'
  "^([0-9]+)(lb|kg)$": 'bodymass'

determineActivityType = (activity) ->
  for own regex, type of typeRegexes
    if activity.rawString.match(new RegExp(regex, 'i'))
      return type
      break

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
  ignoreUp = 0
  Template.activity_info.events
    'focus': (ev) ->
      Session.set 'focused', this._id
      cursor = getCursorPosition()
      if cursor?
        Session.set 'cursorAt', cursor
    'blur': (ev) ->
      Session.set 'focused', ''
    'keydown': (ev) ->
      node = ev.target
      if ev.which in [ENTER_KEY, ARROW_UP, ARROW_DOWN]
        ev.preventDefault()
      else if ev.which in [CMD_KEY, SHIFT_KEY, CTRL_KEY, OPT_KEY]
        modDown = true
      else if modDown
        ignoreUp = ignoreUp + 1
    'keyup': (ev) ->
      node = ev.target
      if ev.which == ENTER_KEY
        # TODO: What's going on here? below not inc'd?
        if ev.shiftKey # Insert above
          new_display_order = this.display_order
          Activities.update {display_order: {$gte: new_display_order}},
            {$inc: {display_order: 1}}
        else # Insert below
          new_display_order = this.display_order + 1
          Activities.update {display_order: {$gte: new_display_order}},
            {$inc: {display_order: 1}}
        newId = Activities.insert rawString: '', display_order: new_display_order
        Session.set 'focused', newId
        Session.set 'cursorAt', -1
      else if ev.which in [ARROW_LEFT, ARROW_RIGHT]
        Session.set 'cursorAt', getCursorPosition()
      else if ev.which == ARROW_UP
        $(node).prev().focus()
      else if ev.which == ARROW_DOWN
        $(node).next().focus()
      else if ev.which in [CMD_KEY, SHIFT_KEY, CTRL_KEY, OPT_KEY]
        Session.set 'cursorAt', getCursorPosition()
        modDown = false
      else if ignoreUp > 0
        ignoreUp = ignoreUp - 1
      else if not modDown
        if ev.which == BACKSPACE_KEY and this.rawString.length == 0
          Activities.update {display_order: {$gt: this.display_order}},
            {$inc: {display_order: -1}}
          Activities.remove this._id
          Session.set 'cursorAt', -1
          $(node).prev().focus()
        else
          Session.set 'cursorAt', getCursorPosition()
          Activities.update this._id, $set:
            rawString: trim($(node).text())
            type: determineActivityType(this)

  Template.activity_info.rendered = ->
    if this.data._id == Session.get 'focused'
      $(this.firstNode).focus()
      range = document.createRange()
      cursor = Session.get 'cursorAt'
      if cursor >= 0
        range.setStart this.firstNode.firstChild, cursor.start
        range.setEnd this.firstNode.firstChild, cursor.end
      else
        if not this.firstNode.firstChild
          this.firstNode.appendChild document.createTextNode('')
        range.selectNodeContents this.firstNode.firstChild
      range.collapse false
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range


if Meteor.is_server
  Meteor.startup ->
    # code to run on server at startup
