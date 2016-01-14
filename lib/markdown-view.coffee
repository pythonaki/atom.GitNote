path = require 'path'
url = require 'url'
marked = require 'marked'
highlight = require 'highlight.js'
GitNote = require './lib-gitnote'
$4 = require './fourdollar'
$4.node()
fs = require 'fs-extra'


fs.remove = $4.makePromise(fs.remove)


{CompositeDisposable, Emitter} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'



marked.setOptions {
  # renderer: new marked.Renderer(),
  gfm: true,
  tables: true,
  breaks: false,
  pedantic: false,
  sanitize: true,    # false 이면 html 태그들이 이스케이프 되지 않고 그대로 적용된다.
  smartLists: true,
  smartypants: false,
  highlight: (code, lang) ->
    try
      highlight.highlight(lang, code).value
    catch e
      code
}

# console.log path.resolve(__dirname)



module.exports =
class MarkdownView extends ScrollView
  @content: ->
    # @div class: 'gitnote-markdown-view native-key-bindings', tabindex: '-1', =>
    @div class: 'gitnote-markdown-view', tabindex: '-1', =>
      # tabindex="-1" 이 없으면 atom.commands.add 가 먹히지 않는다.
      @div class: 'gitnote-markdown-header', =>
        @button
          class: 'btn gitnote-markdown-btn'
          click: 'onClickDelete',
          'Delete'
        @button
          class: 'btn gitnote-markdown-btn'
          click: 'onClickEdit',
          ' Edit '
      @div class: 'gitnote-markdown-content'


  buffer: null
  emitter: null
  disposables: null
  renderer: null


  constructor: (buffer) ->
    console.log 'MarkdownView#constructor()'
    super()

    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add @element, 'atom-gitnote:delete': => @deleteNote()
    @disposables.add atom.commands.add @element, 'atom-gitnote:copy': => @copySelectedText()

    @setupRenderer()
    @setBuffer(buffer)


  destroy: ->
    console.log 'MarkdownView#destroy()'
    @disposables.dispose()
    @element.remove()
    destroyBuffer = true
    for pane in atom.workspace.getPaneItems()
      if pane.getBuffer?() is @buffer and !(pane is this)
        console.log 'pane: ', pane
        destroyBuffer = false
        break
    console.log 'destroyBuffer: ', destroyBuffer
    @buffer.destroy() if destroyBuffer
    @emitter.emit 'did-destroy'


  setBuffer: (buffer) ->
    console.log 'MarkdownView#setBuffer()'
    @buffer = buffer
    @disposables.add @buffer.onDidSave => @updateMarkdown()
    @disposables.add @buffer.onDidDestroy =>
      console.log 'setBuffer: buffer#onDidDestroy'
      atom.project.bufferForPath(@buffer.getPath())
      .then (buffer) =>
        @setBuffer(buffer)
    @updateMarkdown()


  # setupBuffer: ->
  #   @buffer.onDidSave (evt) =>
  #     @updateMarkdown()
  #   @buffer.onDidDestroy (evt) ->
  #     console.log 'buffer did destroy: ', evt


  setupRenderer: () ->
    @renderer = new marked.Renderer()

    @renderer.heading = (text, level, raw) =>
      @_title = text if(!@_title)
      headId = GitNote.createHeadId(text)
      "<h#{level} id=\"#{headId}\">#{text}</h#{level}>"
      # "<a name=\"#{headId}\" class=\"gitnote-anchor\" href=\"##{headId}\">" +
      # "<span class=\"gitnote-header-link\"></span></a>" +
      # "#{text}</h#{level}>"
      # marked.Renderer.prototype.heading.call(@renderer, text, level, raw)

    @renderer.image = (href, title, text) =>
      {protocol, path: myPath} = url.parse(href)
      if(!protocol)
        href = path.resolve(@buffer.getPath(), myPath)
      marked.Renderer.prototype.image.call(@renderer, href, title, text)

    @renderer.link = (href, title, text) =>
      result = marked.Renderer.prototype.link.call(@renderer, href, title, text)
      if text is ':origin:'
        result = "<div class=\"gitnote-markdown-origin\">#{result}</div>"
        # result = result.replace('<a', '<a class="bynote-markdown-origin"')
      result


  updateMarkdown: ->
    console.log 'MarkdownView#updateMarkdown()'
    @_title = null
    @element.querySelector('.gitnote-markdown-content')
    .innerHTML = marked(@buffer.getText(), {renderer: @renderer})
    @updateTitle()


  getTitle: ->
    if(@_title)
      "\@ #{@_title}"
    else
      '@ untitled'


  getLongTitle: ->
    "#{@getTitle()} - #{path.basename(@buffer.getPath())}"


  getPath: ->
    @buffer.getPath()


  scrollIntoView: (id) ->
    console.log 'MarkdownView#scrollIntoView()'
    try
      @element.querySelector('#' + id).scrollIntoViewIfNeeded()
    catch err
      console.error err.stack


  isActive: ->
    atom.workspace.getActivePaneItem() is this


  updateTitle: ->
    console.log 'MarkdownView#updateTitle()'
    @emitter.emit 'did-change-title', @getTitle()


  deleteNote: ->
    console.log 'MarkdownView#deleteNote()'
    confirm = atom.confirm
      message: 'Delete?'
      detailedMessage: "This note will be deleted if you choose 'ok'."
      buttons: ['Cancel', 'Ok']
    if confirm is 1
      mdPath = @getPath()
      if GitNote.isNoteFile(mdPath)
        mdPath = path.dirname(mdPath)
      fs.remove(mdPath)
      .then =>
        @destroy()
        @buffer.destroy()
      .catch (e) =>
        console.error e.stack


  copySelectedText: ->
    atom.clipboard.write(getSelection().toString())


  onClickEdit: (event, element) ->
    console.log 'MarkdownView#onClickEdit'
    atom.commands.dispatch(atom.views.getView(atom.workspace)
      , 'atom-gitnote:toggle-open')


  onClickDelete: (event, element) ->
    @deleteNote()


  # atom.workspace 가 이 뷰가 제거되는지 알기위해 필요하다.
  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback
