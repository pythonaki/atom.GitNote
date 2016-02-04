- fuzzy 말고 다른 검색엔진.

- MarkdownView: 화면이 작아졌을 때 반응형으로.

- MarkdownEditor: 단축기능 구현.

- gitnote:name@repository/note.md#hash 할 수 있다.
  - atom.workspace.open() 에서
    - gitnote:name@repository/note.md#hash :: name@repository 원격지에서 가져온다.
    - gitnote:///this/is/path/note.md#hash :: 해당 경로에서 가져온다.
  - markdown 에서
    - [link](#hash) :: 현재 MarkdownView 에서 찾는다.
    - [link](gitnote:///note.md#hash) :: 해당 work tree에서 찾는다.
    - [link](gitnote:name@repository/note.md#hash) :: name@repository 원격지에서 가져온다.
