path = require 'path'
url = require 'url'
marked = require 'marked'
highlight = require 'highlight.js'
GitNote = require './lib-gitnote'
DmpEditor = require './dmp-editor'
$4 = require './fourdollar'
$4.node()
fs = require 'fs-extra'
rr = require './rather'


fs.remove = $4.makePromise(fs.remove)


{CompositeDisposable, Emitter} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'



marked.setOptions {
  # renderer: new marked.Renderer(),
  gfm: true,
  tables: true,
  breaks: false,
  pedantic: false,
  sanitize: false,    # false 이면 html 태그들이 이스케이프 되지 않고 그대로 적용된다.
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


  emitter: null
  disposables: null
  bufferDispos: null
  renderer: null
  buffer: null
  editor: null
  uri: null
  _hash: null


  constructor: (uri) ->
    console.log 'MarkdownView#constructor()'
    super()

    @emitter = new Emitter()
    @disposables = new CompositeDisposable()
    @disposables.add atom.commands.add @element, 'atom-gitnote:copy': => @copySelectedText()
    @bufferDispos = new CompositeDisposable()

    @setupRenderer()
    @goto(uri) if uri


  destroy: ->
    console.log 'MarkdownView#destroy()'
    @disposables.dispose()
    @element.remove()
    @bufferDispos?.dispose()
    @editor?.destroy()
    @emitter.emit 'did-destroy'


  setupRenderer: () ->
    @renderer = new marked.Renderer()

    @renderer.heading = (text, level, raw) =>
      @_title = text if(!@_title)
      headId = GitNote.createHeadId(text)
      "<h#{level} id=\"#{headId}\" class=\"gitnote-markdown-headline\">#{text}</h#{level}>"

    @renderer.image = (href, title, text) =>
      {protocol, path: myPath, host} = url.parse(href)
      if(!protocol)
        href = path.resolve(path.dirname(@getPath()), myPath)
      else if((protocol is 'http:' or protocol is 'https:') and (rr.isImageFile(href)))
        imgPath = path.resolve(path.dirname(@getPath())
          , GitNote.createName(GitNote.getId(@getPath()), href))
        if(fs.existsSync(imgPath))
          href = imgPath
      # else if(protocol is 'gitnote:')
      #   href = path.resolve(path.dirname(@getPath()), host)
      marked.Renderer.prototype.image.call(@renderer, href, title, text)

    @renderer.link = (href, title, text) =>
      result = marked.Renderer.prototype.link.call(@renderer, href, title, text)
      if text is ':origin:'
        result = "<div class=\"gitnote-markdown-origin\">#{result}</div>"
        # result = result.replace('<a', '<a class="bynote-markdown-origin"')
      result


  setupBuffer: (buffer) ->
    console.log 'MarkdownView#setupBuffer()'
    @bufferDispos?.dispose()
    @editor?.destroy()
    @buffer = buffer
    @editor = new DmpEditor(buffer)
    @bufferDispos.add @buffer.onDidSave => @updateMarkdown()
    @bufferDispos.add @buffer.onDidDestroy => @destroy()


  updateMarkdown: ->
    console.log 'MarkdownView#updateMarkdown()'
    @_title = null
    @element.querySelector('.gitnote-markdown-content')
    .innerHTML = marked(@buffer.getText(), {renderer: @renderer})
    @updateTitle()


  getTitle: ->
    if(@_title)
      "\@ #{@_title}"
    else if(@getPath())
      "\@ #{path.basename(@getPath())}"
    else
      '@ untitled'


  getLongTitle: ->
    "#{@getTitle()} - #{@getPath()}"


  getUri: ->
    @uri


  # getBuff? 와 getPath? 로 gitnote와 관계된 pane인지 확인.
  getPath: ->
    @buffer?.getPath()


  # getBuff? 와 getPath? 로 gitnote와 관계된 pane인지 확인.
  getBuff: ->
    @buffer


  # hash가 id 인지 name 인지 ..
  goto: (uri) ->
    console.log 'MarkdownView#goto()'
    parsed = rr.parseGitNoteUri(uri)
    if @uri and rr.equalGitNoteUri(@uri, uri)
      @uri = uri
      @scrollIntoView(parsed.hash) if parsed.hash
      return Promise.resolve(this)

    @uri = uri
    if parsed.auth and parsed.repository
      # 원격지 라면.. 처리..
    else if parsed.auth or parsed.repository
      # error 처리..
    else if !parsed.pathname
      # error 처리..
    else
      return atom.project.bufferForPath(parsed.pathname) # 절대 경로 이어야함.
      .then (buffer) =>
        @setupBuffer(buffer)
        @updateMarkdown()
        @scrollIntoView(parsed.hash) if parsed.hash
        this

    Promise.resolve(this)


  scrollIntoView: (@_hash) ->
    console.log 'MarkdownView#scrollIntoView()'
    if atom.workspace.getActivePaneItem() is this
      @scrollNow()


  scrollNow: ->
    if @_hash
      try
        el = @element.querySelector(@_hash)
        el = @element.querySelector("[name=\"#{@_hash.slice(1)}\"]") if !el
        el.scrollIntoViewIfNeeded()
        el.classList.add('gitnote-markdown-headline-highlight')
        setTimeout ->
          el.classList.remove('gitnote-markdown-headline-highlight')
        , 300
        @_hash = null
      catch err
        console.error err.stack



  isActive: ->
    atom.workspace.getActivePaneItem() is this


  updateTitle: ->
    console.log 'MarkdownView#updateTitle()'
    @emitter.emit 'did-change-title', @getTitle()


  copySelectedText: ->
    atom.clipboard.write(getSelection().toString())


  onClickEdit: (event, element) ->
    console.log 'MarkdownView#onClickEdit'
    atom.commands.dispatch(atom.views.getView(atom.workspace)
      , 'atom-gitnote:toggle-open')


  onClickDelete: (event, element) ->
    console.log 'MarkdownView#onClickDelete'
    atom.commands.dispatch(atom.views.getView(atom.workspace)
      , 'atom-gitnote:delete')


  # atom.workspace 가 이 뷰가 제거되는지 알기위해 필요하다.
  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback
