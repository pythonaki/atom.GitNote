{SelectListView} = require 'atom-space-pen-views'


module.exports =
class FindView extends SelectListView
  confirmedCallback: null
  cancelledCallback: null

  initialize: ->
    console.log 'FindView#initialize()'
    super
    @addClass('overlay from-top')


  viewForItem: (note) ->
    console.log 'FindView#viewForItem()'
    tag = null
    headline = null
    if(note.headId)
      tag = "<li id=\"gitnote-#{note.headId}\" class=\"gitnote-headline\">"
    else
      tag = "<li class=\"gitnote-headline\">"
    headline = @_indent(note.level) + note.headline
    tag + headline + '</li>'


  getFilterKey: ->
    'fullHeadline'

  confirmed: (note) ->
    console.log 'FindView#confirmed()'
    @confirmedCallback? note

  cancelled: ->
    console.log 'FindView#cancelled()'
    @cancelledCallback?()

  onConfirmed: (callback) ->
    @confirmedCallback = callback

  onCancelled: (callback) ->
    @cancelledCallback = callback


  _indent: (level) ->
    return '' if level is 0
    indent = ''
    indent += '&nbsp;' for i in [1...level]
    indent += '+ '
