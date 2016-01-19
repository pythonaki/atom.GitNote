path = require 'path'
$4 = require '../lib/fourdollar'
$4.debug()
GitNote = require '../lib/lib-gitnote'



describe 'MarkdownView', ->
  [workspaceElement, activationPromise] = []
  dmp04 = path.resolve(__dirname, '../tmp/repo03/dmp04.md')
  editor = null
  mdView = null

  beforeEach ->
    atom.config.set 'atom-gitnote.notePath', path.resolve(__dirname, '../tmp/repo03')
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-gitnote')
    .then ->
      atom.workspace.open(dmp04)
    .then (editor_) ->
      editor = editor_
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
        content = element.querySelector('#' + GitNote.createHeadId('Hello World')).innerHTML
        expect(content).toEqual('Hello World')


    it 'TextEditor에 내용이 변경되었을 때 MarkdownView의 내용도 변경된다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        editor.setText('# foobar')
        editor.save()
      runs ->
        element = mdView.element
        content = element.querySelector('#' + GitNote.createHeadId('foobar')).innerHTML
        expect(content).toEqual('foobar')


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
