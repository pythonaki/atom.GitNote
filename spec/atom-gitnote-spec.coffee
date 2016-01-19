AtomGitNote = require '../lib/atom-gitnote'
GitNote = require '../lib/lib-gitnote'
MarkdownView = require '../lib/markdown-view'
fs = require 'fs-extra'
path = require 'path'
nodegit = require 'nodegit'
$4 = require '../lib/fourdollar'
$4.debug()
$4.node()

fs.remove = $4.makePromise(fs.remove)
fs.ensureDir = $4.makePromise(fs.ensureDir)


# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "atom.GitNote", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    atom.config.set 'atom-gitnote.notePath', path.resolve(__dirname, '../tmp/repo03')
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-gitnote')


  describe 'atom-gitnote:toggle-find', ->
    it 'hides and shows the modal panel', ->
      waitsForPromise ->
        fs.remove path.resolve(__dirname, '../tmp/repo03')

      expect(workspaceElement.querySelector('.find-view')).not.toExist()

      waitsForPromise ->
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'
        # dispatch 해야 atom-gitnote 를 active 할 수 있다.
        activationPromise

      waitsFor ->
        AtomGitNote.modal.isVisible()

      runs ->
        expect(atom.packages.isPackageActive('atom-gitnote')).toBe(true)
        expect(AtomGitNote.findView).toExist()
        expect(AtomGitNote.modal.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'
        expect(AtomGitNote.modal.isVisible()).toBe false


    it 'findView에 노트 리스트를 출력한다.', ->
      waitsForPromise ->
        activationPromise

      gitNote = null
      dic = null
      waitsForPromise ->
        AtomGitNote.getNote()
        .then (gitNote_) ->
          gitNote = gitNote_
          gitNote.create('md')
        .then (notePath) ->
          $4.copy path.resolve(__dirname, '../tmp/dmp01.md'), notePath
        .then ->
          gitNote.dictionary()
        .then (dic_) ->
          dic = dic_
        .then ->
          atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'

      waitsFor ->
        AtomGitNote.modal.isVisible()

      runs ->
        li = workspaceElement.querySelectorAll('.gitnote-headline')
        li = [].slice.call(li)
        expect(li.length).toEqual(5)
        headId = dic[0].headId
        liElemet = workspaceElement.querySelector("\#gitnote-#{headId}")
        expect(liElemet).toExist()
        expect(liElemet.textContent).toEqual('Headline1')


    it '첫번째 headline을 선택한다.', ->
      atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'
      waitsForPromise ->
        activationPromise

      dic = null
      waitsForPromise ->
        AtomGitNote.getNote()
        .then (gitNote) ->
          gitNote.dictionary()
        .then (dic_) ->
          dic = dic_

      waitsFor ->
        AtomGitNote.modal.isVisible()

      runs ->
        findView = AtomGitNote.findView
        findView.confirmed = jasmine.createSpy()
        {list, filterEditorView} = findView
        atom.commands.dispatch(filterEditorView.element, 'core:confirm')
        expect(findView.confirmed).toHaveBeenCalledWith(dic[0])


  describe '.getNote()', ->
    repo01 = path.resolve(__dirname, '../tmp/repo01')
    repo02 = path.resolve(__dirname, '../tmp/repo02')


    it 'GitNote repository를 create 한다.', ->
      gitNote = null
      waitsForPromise ->
        GitNote.create = $4.createSpy(GitNote, GitNote.create)
        fs.remove(repo01)
        .then ->
          AtomGitNote.getNote(repo01)
        .then (gitNote_) ->
          gitNote = gitNote_
      runs ->
        expect(gitNote instanceof GitNote).toBeTruthy()
        expect(GitNote.create.wasCalled).toBeTruthy()
        GitNote.create = GitNote.create.func


    it '같은 경로라면 저장한 GitNote를 반환한다.', ->
      gitNote = null
      waitsForPromise ->
        AtomGitNote.getNote(repo01)
        .then (gitNote_) ->
          gitNote = gitNote_
      runs ->
        expect(gitNote).toEqual(AtomGitNote.getNote._gitNote)


    it 'GitNote repository를 open한다.', ->
      AtomGitNote.getNote._gitNote = null
      gitNote = null
      waitsForPromise ->
        GitNote.open = $4.createSpy(GitNote, GitNote.open)
        AtomGitNote.getNote(repo01)
        .then (gitNote_) ->
          gitNote = gitNote_
      runs ->
        expect(gitNote instanceof GitNote).toBeTruthy()
        expect(GitNote.open.wasCalled).toBeTruthy()
        GitNote.open = GitNote.open.func


    it '엉뚱한 repository는 허용하지 않는다.', ->
      error = false
      waitsForPromise ->
        fs.ensureDir(repo02)
        .then ->
          nodegit.Repository.init(repo02, 0)
        .then ->
          AtomGitNote.getNote(repo02)
        .catch (err) ->
          error = true
      runs ->
        expect(error).toBeTruthy()


  describe 'atom-gitnote:new-markdown', ->
    repo03 = path.resolve(__dirname, '../tmp/repo03')

    it '새 노트 파일(.md)을 TextEditor로 연다.', ->
      waitsForPromise ->
        activationPromise
        .then ->
          atom.commands.dispatch workspaceElement, 'atom-gitnote:new-markdown'

      waitsFor ->
        !!atom.workspace.getActiveTextEditor()

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText('# Hello World')
        expect(editor.getTitle()).toEqual('# Hello World')


    it '이미 열린 노트 파일(.md) 탭 제목을 예쁘게 바꾼다.', ->
      waitsForPromise ->
        activationPromise
      runs ->
        atom.packages.deactivatePackage('atom-gitnote')

      notePath = null
      editor = null

      waitsForPromise ->
        GitNote.open(repo03)
        .then (gitNote_) ->
          gitNote = gitNote_
          gitNote.create('md')
        .then (notePath_) ->
          notePath = notePath_
          atom.workspace.open(notePath)
        .then (editor_) ->
          editor = editor_
          editor.setText('## editor')
      runs ->
        expect(editor.getTitle()).toEqual(path.basename(notePath))

      waitsForPromise ->
        atom.packages.activatePackage('atom-gitnote')
      runs ->
        expect(editor.getTitle()).toEqual('# editor')


  describe 'atom-gitnote:toggle-open', ->
    it 'TextEditor -> MarkdownView, MarkdownView -> TextEditor', ->
      waitsForPromise ->
        activationPromise
        .then ->
          atom.commands.dispatch workspaceElement, 'atom-gitnote:new-markdown'
      waitsFor ->
        !!atom.workspace.getActiveTextEditor()
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText('# Hello World')
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-open'
      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof MarkdownView
      runs ->
        mdView = atom.workspace.getActivePaneItem()
        expect(mdView.getTitle()).toEqual('@ Hello World')
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-open'
      waitsFor ->
        !!atom.workspace.getActiveTextEditor()
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        expect(editor.getText()).toEqual('# Hello World')


  describe 'atom-gitnote:delete', ->
    it 'TextEditor에서 노트파일이 맞다면 삭제할수 있다.', ->
      notePath = null
      confirm = null
      waitsForPromise ->
        activationPromise
        .then ->
          atom.commands.dispatch workspaceElement, 'atom-gitnote:new-markdown'
      waitsFor ->
        !!atom.workspace.getActiveTextEditor()
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        notePath = editor.getPath()
        editor.setText('# Hello World')
        editor.save()
        expect(fs.existsSync(notePath)).toBeTruthy()
      runs ->
        confirm = atom.confirm
        atom.confirm = -> 1
        atom.commands.dispatch workspaceElement, 'atom-gitnote:delete'
      waitsFor ->
        !atom.workspace.getActiveTextEditor()
      runs ->
        atom.confirm = confirm
        expect(fs.existsSync(notePath)).toBeFalsy()


    it 'MarkdownView에서도 노트파일이 맞다면 삭제할 수 있다.', ->
      notePath = null
      confirm = null
      waitsForPromise ->
        activationPromise
        .then ->
          atom.commands.dispatch workspaceElement, 'atom-gitnote:new-markdown'
      waitsFor ->
        !!atom.workspace.getActiveTextEditor()
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        notePath = editor.getPath()
        editor.setText('# Hello World')
        editor.save()
        expect(fs.existsSync(notePath)).toBeTruthy()
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-open'
      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof MarkdownView
      runs ->
        confirm = atom.confirm
        atom.confirm = -> 1
        atom.commands.dispatch workspaceElement, 'atom-gitnote:delete'
      waitsFor ->
        !(atom.workspace.getActivePaneItem() instanceof MarkdownView)
      runs ->
        atom.confirm = confirm
        expect(fs.existsSync(notePath)).toBeFalsy()


    it '관리되지 않는 노트파일은 TextEditor에서는
     delete 안되지만 MarkdownView에서는 delete 할수 있다.', ->
      repo03 = path.resolve(__dirname, '../tmp/repo03')
      dmp01 = path.resolve(repo03, 'dmp01.md')

      waitsForPromise ->
        $4.copy(path.resolve(__dirname, '../tmp/dmp01.md'), dmp01)
        .then ->
          atom.workspace.open(dmp01)
      waitsFor ->
        !!atom.workspace.getActiveTextEditor()
      runs ->
        atom.confirm = $4.createSpy(atom, atom.confirm)
        atom.commands.dispatch workspaceElement, 'atom-gitnote:delete'
        expect(atom.confirm.wasCalled).toBeFalsy()
        atom.confirm = atom.confirm.func
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-open'
      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof MarkdownView
      runs ->
        confirm = atom.confirm
        atom.confirm = -> 1
        atom.commands.dispatch workspaceElement, 'atom-gitnote:delete'
      waitsFor ->
        !(atom.workspace.getActivePaneItem() instanceof MarkdownView)
      runs ->
        atom.confirm = confirm
        expect(fs.existsSync(dmp01)).toBeFalsy()
