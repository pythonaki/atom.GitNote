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

### 노트 저장소 만들기 워크 순서.
1. config:
  - Work Tree:
  - [x] I will save GitHub:
  - GitHub Repository:
  - GitHub ID:
  - GitHub Password:
1. 'Work Tree' 경로가 존재하지 않고, 'GitHub Repository' 가 만들어 지지 않았다면 create 모드이다.
1. 'Work Tree' 경로가 존재하지 않고, 'GitHub Repository' 가 존재한다면 clone 모드이다.
1. 'Work Tree' 경로가 존재하면 open 모드이다.
1. 'Work Tree' 경로가 존재하고 'Work Tree' origin 과 'GitHub Repository' 이 다르고 'GitHub Repository' 가 존재하지 않는다면 origin을 'GitHub Repository' 로 바꿀 것인지 물어본다.
1. 'Work Tree' 경로가 존재하고 'GitHub Repository' 가 존재하고 origin 과 다르다면 에러이다.
