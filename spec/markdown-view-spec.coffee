path = require 'path'
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
      atom.workspace.open('markdown-view://' + dmp04)
    .then (mdView_) ->
      mdView = mdView_


  describe 'MarkdownView#getTitle()', ->
    it 'MarkdownView에 제목.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        expect(mdView.getTitle()).toEqual('@ Hello World')


  describe 'MarkdownView#updateMarkdown()', ->
    it 'MarkdownView에 내용을 표시한다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        element = mdView.element
        content = element.querySelector(
          '#' + GitNote.createHeadId('Hello World')).innerHTML
        expect(content).toEqual('Hello World')


    it 'MarkdownEditor에 내용이 변경되었을 때 MarkdownView의 내용도 변경된다.', ->
      waitsForPromise ->
        activationPromise
        .then ->
          editor.setText('# foobar')
          editor.save()

      runs ->
        element = mdView.element
        content = element.querySelector('#' + GitNote.createHeadId('foobar')).innerHTML
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


    it 'gitnote: 프로토콜 이미지를 올바른 url로 바꾼다.', ->
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
