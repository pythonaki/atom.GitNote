'use babel';

import path from 'path';
import {existsSync, emptyDirSync, copySync} from 'fs-extra';
import {getId, createName} from '../lib/lib-gitnote';
import $4 from '../lib/fourdollar';
import GitNote from '../lib/lib-gitnote';





describe('MarkdownEditor', () => {
  const noteDir = path.resolve(__dirname, '../tmp/repo03')
  let [workspaceElement, activationPromise] = [];
  let editor = null;

  const createNotePath = function() {
    const id = GitNote._createId();
    return path.resolve(noteDir, 'notes', `${id}/${id}.md`);
  }

  beforeEach(() => {
    atom.config.set('atom-gitnote.notePath', noteDir);
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage('atom-gitnote')
    .then(() => {
      return atom.workspace.open(createNotePath());
    })
    .then((_editor) => {
      return editor = _editor;
    });
  });


  describe('MarkdownEditor#getTitle()', () => {
    it('MarkdownEditor 제목을 가져온다.', () => {
      waitsForPromise(() => {
        return activationPromise;
      });
      runs(() => {
        expect(editor.getTitle()).toEqual(`# ${path.basename(editor.getPath())}`);
      });

      waitsForPromise(() => {
        editor.setText('# google');
        return editor.save();
      });
      runs(() => {
        expect(editor.getTitle()).toEqual('# google');
      });
    });
  });


  describe('MarkdownEditor#save()', () => {
    it('원격지의 이미지를 노트의 위치에 다운로드 한다.', () => {
      const img = 'https://www.google.co.kr/logos/doodles/2016/lola-flores-93rd-birthday-5451340874514432-hp.jpg';
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          editor.setText(`# google\n![image](${img})`);
          return editor.save();
        });
      });
      runs(() => {
        const imgPath = path.resolve(path.dirname(editor.getPath())
          , createName(getId(editor.getPath()), img));
        console.log('img path: ', imgPath);
        expect(existsSync(imgPath)).toBeTruthy();
      });
    });
  });


  describe('MarkdownEditor#addSavingFile()', () => {
    it('로컬 이미지를 노트 위치에 복사한다.', () => {
      const naverImg = path.resolve(__dirname, '../tmp/naver.gif');
      let savingImg = null;
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          editor.setText('# Naver Image\n');
          editor.moveToBottom();
          savingImg = editor.addSavingFile(naverImg);
          return editor.save();
        });
      });

      runs(() => {
        expect(existsSync(path.resolve(path.dirname(editor.getPath())
          , savingImg))).toBeTruthy();
      });
    });
  });


  describe('MarkdownEditor Events', () => {
    it('MarkdownEditor#onSuccess()', () => {
      let sucEvt;
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          editor.onSuccess((evt) => {
            sucEvt = evt;
          });
          editor.emitter.emit('success', {target: editor, message: 'success!!'});
        });
      });

      runs(() => {
        expect(sucEvt.target).toEqual(editor);
        expect(sucEvt.message).toEqual('success!!');
      });
    });

    it('MarkdownEditor#onError()', () => {
      let errEvt;
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          editor.onError((evt) => {
            errEvt = evt;
          });
          editor.emitter.emit('error'
            , {target: editor, message: 'error!!'});
        });
      });

      runs(() => {
        expect(errEvt.target).toEqual(editor);
        expect(errEvt.message).toEqual('error!!');
      });
    });
  });


  describe('etc', () => {
    it('노트파일의 폴더를 미리 만들지 않는다.', () => {
      const naverImg = path.resolve(__dirname, '../tmp/naver.gif');
      waitsForPromise(() => {
        return activationPromise
        .then((editor) => {
          editor.setText('# Hasty');
        });
      });

      runs(() => {
        const exists = existsSync(path.dirname(editor.getPath()));
        expect(exists).toBeFalsy();
      });

      waitsForPromise(() => {
        editor.addSavingFile(naverImg);
        return editor.save();
      });

      runs(() => {
        const exists = existsSync(path.dirname(editor.getPath()));
        expect(exists).toBeTruthy();
      });
    });
  });

});
