path = require 'path'
url = require 'url'
marked = require 'marked'
$4 = require './fourdollar'
fs = require 'fs-extra'
{gitnoteUri} = require './rather'

fs.remove = $4.makePromise(fs.remove)

GitNote = require './lib-gitnote'
FindView = require './find-view'
MarkdownView = require './markdown-view'
MarkdownEditor = require './markdown-editor'
{CompositeDisposable} = require 'atom'
resourcePath = atom.config.resourcePath
try
  Editor = require path.resolve resourcePath, 'src', 'editor'
catch e
  # Catch error
TextEditor = Editor ? require path.resolve resourcePath, 'src', 'text-editor'



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
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle-open': => @toggleOpen()
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:delete': => @deleteNote()

    @setupOpener()
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
    .then (notePath) =>
      atom.workspace.open(notePath) # TextEditor를 Promise로 리턴한다.
    .then (editor) =>
      @newNoteCalled = true
      editor


  newMarkdown: ->
    console.log 'AtomGitNote#newMarkdown()'
    @newNote('md')


  toggleOpen: ->
    activePane = atom.workspace.getActivePaneItem()
    return unless notePath = activePane?.getPath?()
    console.log 'AtomGitNote#toggleOpen(): ', notePath

    if path.extname(notePath) is '.md'
      if activePane instanceof TextEditor
        atom.workspace.open('gitnote://' + notePath, split: 'left')
      else if activePane instanceof MarkdownView
        atom.workspace.open(notePath, split: 'left')


  deleteNote: ->
    console.log 'AtomGitNote#deleteNote()'
    pane = atom.workspace.getActivePaneItem()
    if pane.getBuff? and pane.getPath?
      confirm = atom.confirm
        message: 'Delete?'
        detailedMessage: "This note will be deleted if you choose 'ok'."
        buttons: ['Cancel', 'Ok']
      if confirm is 1
        mdPath = pane.getPath()
        if GitNote.isNoteFile(mdPath)
          mdPath = path.dirname(mdPath)
        fs.remove(mdPath)
        .then ->
          pane.getBuff().destroy()
        .catch (e) =>
          console.error e.stack


  # open: (uri, options) ->
  #   atom.workspace.open(uri, options)
  #   .then (view) ->
  #     if view instanceof MarkdownView
  #       console.log 'view.goto()'
  #       return view.goto(uri)
  #     view


  setupOpener: ->
    atom.workspace.addOpener (uriToOpen) =>
      console.log 'AtomGitNote#addOpener(): ', uriToOpen
      if(gitnoteUri.valid(uriToOpen))
        if(gitnoteUri.isMarkdownFile(uriToOpen)) # markdown
          for view in atom.workspace.getPaneItems()
            if (view instanceof MarkdownView) and gitnoteUri.equal(uriToOpen, view.getUri())
              view.goto(uriToOpen)
              return Promise.resolve(view)
          return Promise.resolve(@createMarkdownView(uriToOpen))

    @disposables.add atom.workspace.onDidOpen (evt) =>
      # MarkdownView.scrollNow()
      evt.item.scrollNow?()


  setupFindView: ->
    console.log 'AtomGitNote#setupFindView()'
    @findView = new FindView()
    @modal = atom.workspace.addModalPanel(item: @findView, visible: false)

    @findView.onConfirmed (note) =>
      console.log 'onConfirmed: ', note.id
      @modal.hide()
      uri = 'gitnote://' + note.path
      uri += "\##{note.headId}" if note.headId
      console.log 'uri: ', uri
      atom.workspace.open(uri, split: 'left')
      # .then (mdView) ->
      #   mdView.scrollIntoView(note.headId) if note.headId

    @findView.onCancelled () =>
      console.log 'This view was cancelled'
      @modal.hide()


  setupMdEditor: ->
    console.log 'AtomGitNote#setupMdEditor()'
    @disposables.add atom.workspace.onDidOpen (evt) =>
      console.log 'atom.workspace.onDidOpen'
      return unless evt.item instanceof TextEditor
      notePath = evt.item.getPath()
      if(path.extname(notePath) is '.md' and GitNote.isNoteFile(notePath))
        @createMdEditor(evt.item)

    for editor in atom.workspace.getTextEditors()
      notePath = editor.getPath()
      if(path.extname(notePath) is '.md' and GitNote.isNoteFile(notePath))
        @createMdEditor(editor)


  createMdEditor: (editor) ->
    mdEditor = MarkdownEditor(editor)
    mdEditor.onSuccess (evt) ->
      atom.notifications.addSuccess evt.target.getTitle().slice(2)
        , {detail: evt.message}
    mdEditor.onError (evt) ->
      atom.notifications.addError evt.target.getTitle().slice(2)
        , {detail: evt.message}


  createMarkdownView: (uri) ->
    view = new MarkdownView(uri)
    view.onSuccess (evt) ->
      atom.notifications.addSuccess evt.target.getTitle().slice(2)
        , {detail: evt.message}
    view.onError (evt) ->
      atom.notifications.addError evt.target.getTitle().slice(2)
        , {detail: evt.message}
    view


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
