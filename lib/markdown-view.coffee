{resolve, dirname, basename, extname} = require 'path'
url = require 'url'
marked = require 'marked'
highlight = require 'highlight.js'
GitNote = require './lib-gitnote'
DmpEditor = require './dmp-editor'
$4 = require './fourdollar'
$4.node()
fs = require 'fs-extra'
{isImageFile, gitnoteUri} = require './rather'


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

# console.log resolve(__dirname)



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
      hash = GitNote.createHashName(text)
      "<h#{level} class=\"gitnote-markdown-headline\">" +
      "<a name=\"#{hash}\" class=\"gitnote-anchor\" href=\"\##{hash}\">" +
      "<span class=\"gitnote-markdown-headline-link\"></span>" +
      "</a>" +
      text +
      "</h#{level}>"

    @renderer.image = (href, title, text) =>
      {protocol, path: myPath, host} = url.parse(href)
      if(!protocol)
        href = resolve(dirname(@getPath()), myPath)
      else if((protocol is 'http:' or protocol is 'https:') and (isImageFile(href)))
        imgPath = resolve(dirname(@getPath())
          , GitNote.createName(GitNote.getId(@getPath()), href))
        if(fs.existsSync(imgPath))
          href = imgPath
      # else if(protocol is 'gitnote:')
      #   href = resolve(dirname(@getPath()), host)
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
    content = @element.querySelector('.gitnote-markdown-content')
    content.innerHTML = marked(@buffer.getText(), {renderer: @renderer})
    hashReg = /^#+/
    for link in content.querySelectorAll('a')
      link.addEventListener 'click', (evt) =>
        href = evt.currentTarget.getAttribute('href')
        if hashReg.test(href)
          # 해시 처리.. #hash
          # @scrollIntoView(href)
          parsed = gitnoteUri.parse(@getUri())
          parsed.hash = href
          @goto(gitnoteUri.format(parsed))
        else if gitnoteUri.valid(href) and gitnoteUri.isRemote(href)
          # 원격 처러.. gitnote:name@repository/note.md#hash
          atom.workspace.open(href, {split: 'left'})
        else if gitnoteUri.valid(href) and !gitnoteUri.isRemote(href)
          # 로컬 처리.. gitnote:///note.md#hash
          {pathname, hash} = gitnoteUri.parse(href);
          unless dirname(pathname) is '/'
            msg = "'#{href}': 유효하지 않은 'gitnote:' 프로토콜 uri 이다."
            @emitter.emit 'error', {target: this, message: msg}
            return
          parsed = gitnoteUri.parse(@getUri())
          if gitnoteUri.isRemote(@getUri())
            parsed.pathname = pathname
            parsed.hash = hash
            atom.workspace.open(gitnoteUri.format(parsed), {split: 'left'})
          else
            notesDir = dirname(dirname(parsed.pathname))
            noteDir = basename(pathname, extname(pathname))
            noteFile = basename(pathname)
            parsed.pathname = resolve notesDir, noteDir, noteFile
            parsed.hash = hash
            console.log 'open: local -> local', gitnoteUri.format(parsed)
            atom.workspace.open(gitnoteUri.format(parsed), {split: 'left'})

    @updateTitle()


  goto: (uri) ->
    console.log 'MarkdownView#goto()'
    # 유효하지 않은 uri 이라면..
    unless gitnoteUri.valid(uri)
      msg = 'MarkdownView#goto(): 유효하지 않은 uri 이다.'
      @emitter.emit 'error', {target: this
        , message: msg}
      return Promise.reject(Error(msg))

    parsed = gitnoteUri.parse(uri)
    # 전 uri와 같은 uri이라면..
    if @uri and gitnoteUri.equal(@uri, uri)
      @uri = uri
      @scrollIntoView(parsed.hash)
      return Promise.resolve(this)

    @uri = uri
    if gitnoteUri.isRemote(uri)
      # 원격지 라면.. 처리..
    else
      # 로컬 이라면.. 처러..
      return atom.project.bufferForPath(parsed.pathname) # 절대 경로 이어야함.
      .then (buffer) =>
        @setupBuffer(buffer)
        @updateMarkdown()
        @scrollIntoView(parsed.hash)
        this

    Promise.resolve(this)


  getTitle: ->
    if(@_title)
      "\@ #{@_title}"
    else if(@getPath())
      "\@ #{basename(@getPath())}"
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


  scrollIntoView: (@_hash) ->
    console.log 'MarkdownView#scrollIntoView()'
    if atom.workspace.getActivePaneItem() is this
      @scrollNow()


  scrollNow: ->
    console.log 'MarkdownView#scrollNow(): ', @_hash
    if @_hash
      try
        # hash가 id 인지 name 인지 ..
        el = @element.querySelector("[name=\"#{@_hash.slice(1)}\"]")
        el = @element.querySelector(@_hash) if !el
        el.scrollIntoView()
        el.classList.add('gitnote-markdown-headline-highlight')
        setTimeout ->
          el.classList.remove('gitnote-markdown-headline-highlight')
        , 300
        # @_hash = null
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


  onSuccess: (callback) ->
    @emitter.on 'success', callback


  onError: (callback) ->
    @emitter.on 'error', callback
