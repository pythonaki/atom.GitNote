'use babel';


import rr from '../lib/rather';
import {resolve} from 'path';
import {existsSync, remove} from 'fs-extra';


describe('rather#download()', () => {
  it('redirect 되는 파일 다운로드 할수 있다.', () => {
    const url01 = 'https://badge.fury.io/js/marked.png';
    const url02 = 'http://img.shields.io/npm/dm/fs-extra.svg';
    const file01 = resolve(__dirname, '../tmp/marked.png');
    const file02 = resolve(__dirname, '../tmp/fs-extra.svg');
    waitsForPromise(() => {
      return remove(file01)
      .then(() => {
        return remove(file02);
      })
      .then(() => {
        return rr.download(url01, file01);
      })
      .then(() => {
        return rr.download(url02, file02);
      });
    });

    runs(() => {
      expect(existsSync(file01)).toBeTruthy();
      expect(existsSync(file02)).toBeTruthy();
    });
  });


  it('이미지 파일인지 채크한다.', () => {
    expect(rr.isImageFile('hello.png')).toBeTruthy();
    expect(rr.isImageFile('foo/bar/world.JPG')).toBeTruthy();
  });
});
