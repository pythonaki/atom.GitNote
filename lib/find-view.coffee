{SelectListView} = require 'atom-space-pen-views'


module.exports =
class FindView extends SelectListView
  confirmedCallback: null
  cancelledCallback: null

  initialize: ->
    super
    @addClass('overlay from-top')


  viewForItem: (note) ->
    if(note.headId)
      "<li id=\"gitnote-#{note.headId}\" class=\"gitnote-headline\">#{note.headline}</li>"
    else
      "<li class=\"gitnote-headline\">#{note.headline}</li>"


  getFilterKey: ->
    'headline'

  confirmed: (note) ->
    @confirmedCallback? note

  cancelled: ->
    @cancelledCallback?()

  onConfirmed: (callback) ->
    @confirmedCallback = callback

  onCancelled: (callback) ->
    @cancelledCallback = callback
