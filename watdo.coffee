Activities = new Meteor.Collection('Activities')

[ARROW_LEFT, ARROW_RIGHT, ARROW_UP, ARROW_DOWN] = [ 37, 39, 38, 40 ]
ENTER_KEY = 13
BACKSPACE_KEY = 8

getCursorPosition = () ->
  sel = window.getSelection()
  if not sel?
    return 0
  if sel.rangeCount > 0
    sel.getRangeAt(0).startOffset

trim = (str) ->
  str.replace(/^\s*/, '').replace(/\s*$/, '')

if Meteor.is_client

  Template.input.prompt = ->
    (new Date()).toLocaleDateString()

  Template.input.activities = ->
    Activities.find {}, sort: {display_order: 1}

  updateEditTimeout = null
  Template.activity_info.events
    'focus': (ev) ->
      console.log 'focus'
      Session.set 'focused', this._id
    'blur': (ev) ->
      console.log 'blur'
      Session.set 'focused', ''
    'keyup': (ev) ->
      node = ev.target
      console.log 'keycode = ', ev.which
      if ev.which == ENTER_KEY
        ev.preventDefault()
        new_display_order = this.display_order + 1
        if ev.shiftKey
          new_display_order = this.display_order
        Activities.update {display_order: {$gte: new_display_order}}, {$inc: {display_order: 1}}
        newId = Activities.insert rawString: ' ', display_order: new_display_order
        Session.set 'focused', newId
        Session.set 'cursorAt', 0
      else if ev.which in [ARROW_LEFT, ARROW_RIGHT]
        Session.set 'cursorAt', getCursorPosition()
      else
        if ev.which == BACKSPACE_KEY and this.rawString.length == 0
          Activities.update {display_order: {$gt: this.display_order}}, {$inc: {display_order: -1}}
          Activities.remove this._id
        else
          Session.set 'cursorAt', getCursorPosition()
          Activities.update this._id, $set: {rawString: trim($(node).text())}

  Template.activity_info.rendered = ->
    if this.data._id == Session.get 'focused'
      $(this.firstNode).focus()
      cursor = Session.get 'cursorAt'
      range = document.createRange()
      range.setStart this.firstNode.firstChild, cursor
      range.collapse true
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range


if Meteor.is_server
  Meteor.startup ->
    # code to run on server at startup
