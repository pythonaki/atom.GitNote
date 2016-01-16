path = require 'path'
url = require 'url'
marked = require 'marked'
$4 = require './fourdollar'
fs = require 'fs-extra'

fs.remove = $4.makePromise(fs.remove)

GitNote = require './lib-gitnote'
FindView = require './find-view'
MarkdownView = require './markdown-view'
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
    @setupOpener()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @disposables = new CompositeDisposable
    # Register command that toggles this view
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle-find': => @toggleFind()
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:new-markdown': => @newMarkdown()
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:toggle-open': => @toggleOpen()
    @disposables.add atom.commands.add 'atom-workspace', 'atom-gitnote:delete': => @deleteNote()

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
        atom.workspace.open('markdown-view://' + notePath, split: 'left')
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


  setupOpener: ->
    atom.workspace.addOpener (uriToOpen) =>
      console.log 'AtomGitNote#addOpener(): ', uriToOpen
      try
        {protocol, host, path: myPath} = url.parse(uriToOpen)
      catch err
        console.log err.stack
        return

      if(protocol is 'markdown-view:')
        return @findMarkdownView(host + myPath)


  setupFindView: ->
    console.log 'AtomGitNote#setupFindView()'
    @findView = new FindView()
    @modal = atom.workspace.addModalPanel(item: @findView, visible: false)

    @findView.onConfirmed (note) =>
      console.log 'onConfirmed: ', note.id
      @modal.hide()
      uri = 'markdown-view://' + note.path
      # uri += "\##{note.headId}" if note.headId
      atom.workspace.open(uri, split: 'left')
      .then (mdView) ->
        mdView.scrollIntoView(note.headId) if note.headId

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

    # getBuff? 와 getPath? 로 gitnote와 관계된 pane인지 확인.
    editor.getBuff = ->
      @getBuffer()

    editor.emitter.emit 'did-change-title', editor.getTitle()


  findMarkdownView: (notePath) ->
    console.log 'AtomGitNote#findMarkdownView()'
    for view in atom.workspace.getPaneItems()
      if (view instanceof MarkdownView) and path.resolve(view.getPath()) is path.resolve(notePath)
        return Promise.resolve(view)
    atom.project.bufferForPath(notePath)
    .then (buffer) ->
      new MarkdownView(buffer)


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
