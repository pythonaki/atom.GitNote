'use babel';

import path from 'path';
import {existsSync, emptyDirSync, copySync} from 'fs-extra';
import {createImageName} from '../lib/lib-gitnote';
import $4 from '../lib/fourdollar';



describe('MarkdownEditor', () => {
  const noteDir = path.resolve(__dirname, '../tmp/notes/note01');
  const notePath = path.resolve(noteDir, 'note01.md');
  let [workspaceElement, activationPromise] = [];
  let editor = null;

  emptyDirSync(path.resolve(__dirname, '../tmp/notes'));
  copySync(path.resolve(__dirname, '../tmp/note01.md'), notePath);

  beforeEach(() => {
    atom.config.set('atom-gitnote.notePath', path.resolve(__dirname, '../tmp/repo03'));
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage('atom-gitnote')
    .then(() => {
      return atom.workspace.open(notePath);
    })
    .then((editor_) => {
      return editor = editor_;
    });
  });


  describe('MarkdownEditor#getTitle()', () => {
    it('MarkdownEditor 제목을 가져온다.', () => {
      waitsForPromise(() => {
        return activationPromise;
      });
      runs(() => {
        expect(editor.getTitle()).toEqual('# google');
      });
    });
  });


  describe('MarkdownEditor#save()', () => {
    it('원격지의 이미지를 노트의 위치에 다운로드 한다.', () => {
      const img = 'https://www.google.co.kr/logos/doodles/2016/lola-flores-93rd-birthday-5451340874514432-hp.jpg'
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          return editor.save();
        });
      });
      runs(() => {
        expect(existsSync(
          path.resolve(noteDir, createImageName(img)))).toBeTruthy();
      });
    });
  });
});
