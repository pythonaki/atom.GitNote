path = require 'path'
GitNote = require './lib-gitnote'
marked = require 'marked'
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
  newNoteCalled: false


  activate: (state) ->
    console.log 'AtomGitNote#activate()'
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @disposables = new CompositeDisposable
    # Register command that toggles this view
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle-find': => @toggleFind()
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:new-markdown': => @newMarkdown()

    @setupFindView()
    @setupMdEditor()


  deactivate: ->
    console.log 'AtomGitNote#deactivate()'
    @modal.destroy()
    # @findView.destroy()
    @disposables.dispose()


  serialize: ->
    # gitnoteViewState: @gitNoteView.serialize()


  toggleFind: ->
    console.log 'AtomGitNote#toggleFind()'
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


  newNote: (ext) ->
    console.log 'AtomGitNote#newNote()'
    @newNoteCalled = false
    AtomGitNote.getNote()
    .then (gitNote) ->
      gitNote.create(ext)
    .then (notePath) ->
      atom.workspace.open(notePath) # TextEditor를 Promise로 리턴한다.
    .then (editor) =>
      console.log 'newNoteCalled'
      @newNoteCalled = true
      editor


  newMarkdown: ->
    console.log 'AtomGitNote#newMarkdown()'
    @newNote('md')


  setupFindView: ->
    console.log 'AtomGitNote#setupFindView()'
    @findView = new FindView()
    @modal = atom.workspace.addModalPanel(item: @findView, visible: false)

    @findView.onConfirmed (note) =>
      console.log 'onConfirmed: ', note.id
      @modal.hide()
      atom.workspace.open(note.path)
      # atom.workspace.open("bynote://view/#{note.noteId}", split: 'left')

    @findView.onCancelled () =>
      console.log 'This view was cancelled'
      @modal.hide()


  setupMdEditor: ->
    console.log 'AtomGitNote#setupMdEditor()'
    @disposables.add atom.workspace.onDidOpen (evt) =>
      console.log 'atom.workspace.onDidOpen'
      return if(!evt.item.buffer)
      notePath = evt.item.getPath()
      if(path.extname(notePath) is '.md' and GitNote.isNoteFile(notePath))
        @makeMdEditor(evt.item)

    for editor in atom.workspace.getTextEditors()
      notePath = editor.getPath()
      if(path.extname(notePath) is '.md' and GitNote.isNoteFile(notePath))
        @makeMdEditor(editor)


  makeMdEditor: (editor) ->
    console.log 'AtomGitNote#makeMdEditor()'
    editor.getTitle = ->
      title = null
      renderer = new marked.Renderer()
      renderer.heading = (text, level) ->
        title = text if(!title)
      marked(@getText(), {renderer})
      if(title?)
        return "\# #{title}"
      else
        return '# untitled'

    editor.getLongTitle = ->
      "#{@getTitle()} - #{path.basename(@buffer.getPath())}"

    editor.save = ->
      @buffer.save()
      @emitter.emit 'did-change-title', @getTitle()
      @emitter.emit 'saved', {target: this}

    editor.saveAs = (filePath) ->
      msg = "Don't allow saveAs!!"
      console.error msg

    editor.emitter.emit 'did-change-title', editor.getTitle()


  getNote: (notePath) ->
    console.log 'AtomGitNote.getNote()'
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
