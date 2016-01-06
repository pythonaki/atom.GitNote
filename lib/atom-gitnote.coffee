path = require 'path'
GitNote = require './lib-gitnote'
FindView = require './find-view'
{CompositeDisposable} = require 'atom'



getUserHome = (childPath) ->
  process = require 'process'
  path.resolve(process.env.HOME || process.env.USERPROFILE, childPath)



module.exports = AtomGitNote =
  config:
    notePath:
      title: 'GitNote Path:'
      type: 'string'
      order: 1
      default: getUserHome('gitnote')


  findView: null
  modal: null
  disposables: null


  activate: (state) ->
    @setupFindView()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @disposables = new CompositeDisposable
    # Register command that toggles this view
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle-find': => @toggleFind()


  deactivate: ->
    @modal.destroy()
    # @findView.destroy()
    @disposables.dispose()


  serialize: ->
    # gitnoteViewState: @gitNoteView.serialize()


  toggleFind: ->
    console.log 'toggleFind'
    if @modal.isVisible()
      @modal.hide()
    else
      AtomGitNote.getNote()
      .then (gitNote) =>
        gitNote.dictionary()
      .then (dic) =>
        @findView.setItems(dic)
        @modal.show()
        @findView.focusFilterEditor()


  setupFindView: ->
    @findView = new FindView()
    @modal = atom.workspace.addModalPanel(item: @findView, visible: false)

    @findView.onConfirmed (note) =>
      console.log 'onConfirmed: ', note.id
      @modal.hide()
      # atom.workspace.open("bynote://view/#{note.noteId}", split: 'left')

    @findView.onCancelled () =>
      console.log 'This view was cancelled'
      @modal.hide()


  getNote: (notePath) ->
    if(!notePath)
      notePath = atom.config.get('atom-gitnote.notePath')
    if(AtomGitNote.getNote._gitNote and AtomGitNote.getNote._gitNote.workDir is notePath)
      return Promise.resolve(AtomGitNote.getNote._gitNote)
    GitNote.wasInited(notePath)
    .then (inited) ->
      if inited
        return GitNote.open(notePath)
        .then (gitNote) ->
          AtomGitNote.getNote._gitNote = gitNote
      else
        return GitNote.create(notePath)
        .then (gitNote) ->
          AtomGitNote.getNote._gitNote = gitNote
