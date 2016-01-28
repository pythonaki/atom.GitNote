'use babel';


import rr from '../lib/rather';
import {resolve} from 'path';
import {existsSync, remove} from 'fs-extra';


describe('rather', () => {
  describe('rather#download()', () => {
    it('redirect 되는 파일 다운로드 할수 있다.', () => {
      const url01 = 'https://badge.fury.io/js/marked.png';
      const url02 = 'http://img.shields.io/npm/dm/fs-extra.svg';
      const url03 = 'https://raw.github.com/alrra/browser-logos/master/chrome/chrome_48x48.png';
      const file01 = resolve(__dirname, '../tmp/marked.png');
      const file02 = resolve(__dirname, '../tmp/fs-extra.svg');
      const file03 = resolve(__dirname, '../tmp/chrome_48x48.png');
      waitsForPromise(() => {
        return Promise.all([remove(file01), remove(file02), remove(file03)])
        .then(() => {
          const promises = [
            rr.download(url01, file01),
            rr.download(url02, file02),
            rr.download(url03, file03)
          ];
          return Promise.all(promises);
        });
      });

      runs(() => {
        expect(existsSync(file01)).toBeTruthy();
        expect(existsSync(file02)).toBeTruthy();
        expect(existsSync(file03)).toBeTruthy();
      });
    });


    it('이미지 파일인지 채크한다.', () => {
      expect(rr.isImageFile('hello.png')).toBeTruthy();
      expect(rr.isImageFile('foo/bar/world.JPG')).toBeTruthy();
    });
  });
});
