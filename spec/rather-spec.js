'use babel';


import rr, {gitnoteUri} from '../lib/rather';
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


  describe('gitnoteUri', () => {
    it('gitnoteUri.parse(): 원격지.', () => {
      const parsed = gitnoteUri.parse('gitnote:auth@repository/pathname.md#hash');
      expect('gitnote:').toEqual(parsed.protocol);
      expect('auth').toEqual(parsed.auth);
      expect('repository').toEqual(parsed.repository);
      expect('/pathname.md').toEqual(parsed.pathname);
      expect('#hash').toEqual(parsed.hash);
      expect('.md').toEqual(parsed.extname);
    });

    it('gitnoteUri.parse(): 로컬.', () => {
      const parsed = gitnoteUri.parse('gitnote:///pathname.md#hash');
      expect('gitnote:').toEqual(parsed.protocol);
      expect(null).toEqual(parsed.auth);
      expect('').toEqual(parsed.repository);
      expect('/pathname.md').toEqual(parsed.pathname);
      expect('#hash').toEqual(parsed.hash);
      expect('.md').toEqual(parsed.extname);
    });

    it('gitnoteUri.parse(): gitnote: 프로토콜이 아니라면 null을 반환한다.', () => {
      const parsed = gitnoteUri.parse('pathname.md#hash');
      expect(null).toEqual(parsed);
    });


    it('gitnoteUri.format(): parse 된것을 다시 ginoteUri 포멧으로 바꿔도 같아야 한다.', () => {
      const uri = 'gitnote:auth@repository/pathname.md#hash';
      const parsed = gitnoteUri.parse(uri);
      expect(gitnoteUri.format(parsed)).toEqual(uri);
    });

    it('gitnoteUri.format(): format이 내가 원하는 방향이어야 한다.', () => {
      expect(gitnoteUri.format({
        protocol: 'gitnote:',
        auth: 'auth',
        repository: 'repository'
      })).toEqual('gitnote:auth@repository');
      expect(gitnoteUri.format({
        protocol: 'gitnote:',
        auth: 'auth',
        repository: 'repository',
        pathname: '/pathname.md',
        hash: '#hash'
      })).toEqual('gitnote:auth@repository/pathname.md#hash');
    });


    it('gitnoteUri.equal(): hash를 제외한 모든 uri가 같은지 검사한다.', () => {
      const uri1 = 'gitnote:auth@repository/pathname.md';
      const uri2 = 'gitnote:auth@repository/pathname.md#hash'
      expect(gitnoteUri.equal(uri1, uri2)).toBeTruthy();
    });

    it('gitnoteUri.valid(): 유효한 uri인지 검사한다.', () => {
      const uri1 = 'foo/bar/note.md';
      const uri2 = 'gitnote:';
      const uri3 = 'gitnote:auth@';
      const uri4 = 'gitnote:auth@repository';
      const uri5 = 'gitnote:auth@repository/foo/bar/note.md?search=hello';
      const uri6 = 'gitnote:auth@repository/note.md';
      const uri7 = 'gitnote:auth@repository/note.md#hash';
      const uri8 = 'gitnote:///foo/bar/note.md';
      expect(gitnoteUri.valid(uri1)).toBeFalsy();
      expect(gitnoteUri.valid(uri2)).toBeFalsy();
      expect(gitnoteUri.valid(uri3)).toBeFalsy();
      expect(gitnoteUri.valid(uri4)).toBeTruthy();
      expect(gitnoteUri.valid(uri5)).toBeFalsy();
      expect(gitnoteUri.valid(uri6)).toBeTruthy();
      expect(gitnoteUri.valid(uri7)).toBeTruthy();
      expect(gitnoteUri.valid(uri8)).toBeTruthy();
    });
  });
});
