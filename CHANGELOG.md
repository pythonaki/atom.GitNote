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
