path = require 'path'
fs = require 'fs'
$4 = require '../lib/fourdollar'
$4.debug()
GitNote = require '../lib/lib-gitnote'



describe 'MarkdownView', ->
  [workspaceElement, activationPromise] = []
  dmp04 = path.resolve(__dirname, '../tmp/repo03/notes/dmp04/dmp04.md')
  editor = null
  mdView = null

  beforeEach ->
    atom.config.set 'atom-gitnote.notePath', path.resolve(__dirname, '../tmp/repo03')
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-gitnote')
    .then ->
      atom.workspace.open(dmp04)
    .then (_editor) ->
      editor = _editor
      editor.setText('# Hello World')
      atom.workspace.open('gitnote://' + dmp04)
    .then (mdView_) ->
      mdView = mdView_


  describe 'MarkdownView#getTitle()', ->
    it 'MarkdownView에 제목.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        expect(mdView.getTitle()).toEqual('@ Hello World')
      waitsForPromise ->
        editor.setText('- no title')
        editor.save()
      runs ->
        expect(mdView.getTitle()).toEqual("@ #{path.basename(mdView.getPath())}")


  describe 'MarkdownView#updateMarkdown()', ->
    it 'MarkdownView에 내용을 표시한다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        query = "a[name=\"#{GitNote.createHashName('Hello World')}\"]"
        content = mdView.element.querySelector(query).parentElement.textContent
        expect(content).toEqual('Hello World')


    it 'MarkdownEditor에 내용이 변경되었을 때 MarkdownView의 내용도 변경된다.', ->
      waitsForPromise ->
        activationPromise
        .then ->
          editor.setText('# foobar')
          editor.save()

      runs ->
        query = "a[name=\"#{GitNote.createHashName('foobar')}\"]"
        content = mdView.element.querySelector(query).parentElement.textContent
        expect(content).toEqual('foobar')


    it 'MarkdownEditor에 의해 이미지가 다운로드 됐으면 MarkdownView <img> src도 로컬 이미지 경로로 바뀐다.', ->
      waitsForPromise ->
        activationPromise
        .then ->
          editor.setText('# Naver\n![naver](http://img.naver.net/static/www/u/2013/0731/nmms_224940510.gif)')
          editor.save()

      runs ->
        imgPath = path.resolve(path.dirname(dmp04)
          , GitNote.createName(GitNote.getId(dmp04), 'http://img.naver.net/static/www/u/2013/0731/nmms_224940510.gif'))
        element = mdView.element
        imgs = element.querySelectorAll("img[src=\"#{imgPath}\"]")
        expect(imgs.length).toEqual(1)


    it '로컬 이미지를 올바른 url로 바꾼다.', ->
      naverImg = path.resolve(__dirname, '../tmp/naver.gif')
      savingImg = null;
      waitsForPromise ->
        activationPromise
        .then ->
          editor.setText('# Naver Image\n')
          editor.moveToBottom()
          savingImg = editor.addSavingFile(naverImg)
          editor.save()

      runs ->
        imgPath = path.resolve path.dirname(editor.getPath()), savingImg
        element = mdView.element
        imgs = element.querySelectorAll("img[src=\"#{imgPath}\"]")
        expect(imgs.length).toEqual(1)
        expect(fs.existsSync(imgPath)).toBeTruthy()


  describe 'buffer destroy', ->
    it 'buffer destroy 되면 MarkdownView도 destroy 된다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        editor.destroy = $4.createSpy(editor, editor.destroy)
        mdView.destroy = $4.createSpy(mdView, mdView.destroy)
        editor.getBuffer().destroy()
        expect(editor.destroy.wasCalled).toBeTruthy()
        expect(mdView.destroy.wasCalled).toBeTruthy()

    it '해당 노트와 관련된 pane들을 모두 닫으면 buffer도 destroy 되야 한다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        buffer = mdView.getBuff()
        buffer.destroy = $4.createSpy(buffer, buffer.destroy)
        editor.destroy()
        mdView.destroy()
        expect(buffer.destroy.wasCalled).toBeTruthy()


  describe 'MarkdownView#goto()', ->
    it '해당 hash로 하이라이트 된다.', ->
      hash = GitNote.createHashName('Hello World')
      waitsForPromise ->
        activationPromise
        .then (mdView) ->
          mdView.goto('gitnote://' + dmp04 + "\##{hash}")
      runs ->
        el = mdView.element.querySelector("[name=\"#{hash}\"]")
        # el = mdView.element.querySelector("\##{hash}")
        expect(el).toBeTruthy()
        expect(el.classList.contains('gitnote-markdown-headline-highlight')).toBeTruthy()

    it '유효하지 않은 uri이라면 onError 될 것이다.', ->
      [error, errEvt, undef] = []
      waitsForPromise ->
        activationPromise
        .then (mdView) ->
          mdView.onError (evt) ->
            errEvt = evt
          mdView.goto('gitnote:auth@repo/foo/bar/note.md')
        .catch (_err) ->
          error = _err
      runs ->
        expect(error).toBeDefined()
        expect(errEvt).toBeDefined()
        expect(undef).toBeUndefined()


  describe 'MarkdownView Events', ->
    it 'MarkdownView#onSuccess()', ->
      sucEvt = null;
      waitsForPromise ->
        activationPromise
        .then (mdView) ->
          mdView.onSuccess (evt) ->
            sucEvt = evt
          mdView.emitter.emit 'success', {target: mdView, message: 'success!!'}
      runs ->
        expect(sucEvt.target).toEqual(mdView)
        expect(sucEvt.message).toEqual('success!!')

    it 'MarkdownView#onError()', ->
      errEvt = null;
      waitsForPromise ->
        activationPromise
        .then (mdView) ->
          mdView.onError (evt) ->
            errEvt = evt
          mdView.emitter.emit 'error', {target: mdView, message: 'error!!'}
      runs ->
        expect(errEvt.target).toEqual(mdView)
        expect(errEvt.message).toEqual('error!!')


  describe 'MarkdownView link 이동.', ->
    # bug가 있다.
    # it '#hash 로 이동.', ->
    #   waitsForPromise ->
    #     activationPromise
    #     .then (mdView) ->
    #       editor.setText '# Test hash click\n' + '[link](#hash)\n' + '<a name="hash">here</a>'
    #       editor.save()
    #     .then ->
    #       el = mdView.element.querySelector('a[href="#hash"]')
    #       event = new MouseEvent('click', {
    #         bubbles: true,
    #         cancelable: true,
    #         view: window
    #       })
    #       el.dispatchEvent(event)
    #   runs ->
    #     el = mdView.element.querySelector('a[name="hash"]')
    #     expect(el).toBeTruthy()
    #     expect(el.classList.contains('gitnote-markdown-headline-highlight')).toBeTruthy()

    it '"gitnote:///pathname.md#hash" 로 이동.', ->
      dmp05 = path.resolve(__dirname, '../tmp/repo03/notes/dmp05/dmp05.md')
      target = null
      waitsForPromise ->
        activationPromise
        .then ->
          atom.workspace.open(dmp05)
        .then (_editor) ->
          target = _editor
          target.setText '# Target\n ### here'
          target.save()
        .then ->
          here = "gitnote:///#{path.basename(target.getPath())}\#here"
          editor.setText "\# Link Click\n- [link](#{here})"
          editor.save()
        .then ->
          here = "gitnote:///#{path.basename(target.getPath())}\#here"
          el = mdView.element.querySelector("a[href=\"#{here}\"]")
          event = new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
            view: window
          })
          el.dispatchEvent(event)

      runs ->
        here = "gitnote://#{dmp05}\#here"
        view = atom.workspace.getActivePaneItem()
        expect(view.getUri()).toEqual("gitnote://#{dmp05}\#here")
        el = view.element.querySelector('a[name="here"]')
        expect(el).toBeTruthy()
        expect(el.classList.contains('gitnote-markdown-headline-highlight')).toBeTruthy()
