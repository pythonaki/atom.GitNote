## v0.1

#### v0.1.0

- [x] fourdollar.js 추가.
- [x] lib-gitnote에 필요한 package 추가.
- [x] atom-gitnote: lib-gitnote 추가.
- [x] AtomGitNote.getNote(): 구현.
- [x] FindView 구현.


#### v0.1.1

- [x] 새 노트 생성후 text editor open
- [x] markdown text editor 라면 탭의 제목 headline으로.
- [x] .setupTextEditor()
- [x] .makeMdEditor()
- [x] FindView.viewForItem: level에 맞게 이쁘게^^&


#### v0.1.2

- [x] MarkdownView 구현.
- [x] MarkdownView: 해당 headline으로 스크롤 이동. scrollIntoView
- [x] MarkdownView: save 했을때 title 제대로 바꾸기.
- [x] bugfix: TextEditor를 닫았을 때 MarkdownView의 buffer가 destroy 되는 문제.
- [x] atom-gitnote:toggle-open
- [x] atom-gitnote:delete
- [x] atom-gitnote:copy


#### v0.1.3

- [x] MarkdownView: TextEditor를 추가해 buffer가 destroy되는 걸 방지.
- [x] MarkdownView: getBuffer()를 getBuff() 로 바꾸기. (Atom이 MarkdownView를 TextEditor로 잘못인식하는 문제 해결.)
- [x] atom-gitnote:delete를 workspace 범위로 바꿈.


#### v0.1.4

- [x] atom-gitnote-spec: 추가.
- [x] atom-markdown-view-spec: 작성.


#### v0.1.5.a

- [x] makeMdEditor를 단일 파일로 분리한다. -> MarkdownEditor
- [x] MarkdownView#scrollIntoView: 이동후 제목 강조.
- [x] MarkdownEditor: save할때 원격 이미지 파일을 로컬로 다운로드 하기.
- [x] markdown-editor-spec 작성.


#### v0.1.5.b

- [x] MarkdownView: 원격 이미지 파일이라면 로컬에 있는지 확인하고 있다면 로컬의 이미지를 태그한다.


#### v0.1.5c

- [x] MarkdownEditor: 로컬 이미지 파일 삽입 기능 구현.
- [x] MarkdownView#setupRenderer(): 'gitnote:' 프로토콜 이미지를 적합하게 바꾸기.
- [x] MarkdownEditor#save(): onSuccess, onError 작성.
- [x] AtomGitNote: Notification 기능 구현한다.


#### v0.1.6a

- [x] MarkdownEditor: 해당 노트파일의 폴더를 미리 만들지 않는다.


#### v0.1.6b

- [x] bugfix: 원격 이미지 중 다운로드 되지 않는 것이 있다. (https://badge.fury.io/js/marked.png)(http://img.shields.io/npm/dm/fs-extra.svg)


#### v0.1.6c

- [x] bugfix: MarkdownEditor: 이미지 파일창이 여러번 열린다.
- [x] 외부 Editor에서 .md를 MarkdownView 로 볼때 제목 `@ untitled` 를 .md 파일명으로.


#### v0.1.6d

- [x] gitnote: 프로토콜 없애기.


#### v0.1.7a

- [x] atom.workspace.open() 에서 'gitnote:' 프로토콜 사용.
  - gitnote:///this/is/path/note.md#hash :: 해당 경로에서 가져온다.


#### v0.1.7b

- [x] gitnote: uri 의 모든 처리는 MarkdownView 가 한다. (#goto())


#### v0.1.7c

- [x] rather.js: gitnoteUri 구현을 보다 유용하게.
- [x] MarkdownView#goto(): 좀더 다듬자.
- [x] MarkdownView: onSuccess, onError.


#### v0.1.8a

- [x] MarkdownView: 노트안에 &lt;a href="#hash"&gt; 등이 바르게 동작하게 하기.
  - "#hash"
  - "gitnote:///another.md#hash"
  - "gitnote:auth@repository/note.md#hash" (나중에)
- [x] MarkdownView#setupRenderer(): headline을 GitHub의 방법으로 hash를 주자.
- [x] MarkdownView#scrollNow(): highlight 다시 제대로.
- [x] bugfix: MarkdownEditor#insertImage(): 아직도 창이 반복해서 열린다.


#### v0.1.8b

- [x] MarkdownView: "gitnote:///another.md#hash" spec


#### v0.1.9

- [x] 버젼 완료.
