GitNoteView = require './atom-gitnote-view'
{CompositeDisposable} = require 'atom'

module.exports = GitNote =
  gitNoteView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @gitNoteView = new GitNoteView(state.gitnoteViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @gitNoteView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @gitNoteView.destroy()

  serialize: ->
    gitnoteViewState: @gitNoteView.serialize()

  toggle: ->
    console.log 'GitNote was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
