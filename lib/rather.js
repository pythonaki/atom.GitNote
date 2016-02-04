'use babel';

import {basename, extname} from 'path';
import {parse as parseUrl, format as formatUrl} from 'url';
import {createWriteStream} from 'fs';
import {http, https} from 'follow-redirects';



const imgFileTypes = [
  '.png',
  '.gif',
  '.jpg',
  '.jpeg',
  '.svg'
];


const mdExts = [
  '.md',
  '.markdown'
];


const htmlExts = [
  '.html',
  '.htm'
];


function isIn(target, array) {
  for(el of array) {
    if(target === el) {
      return true;
    }
  }
  return false;
}


function isImageFile(filename) {
  return isIn(extname(filename).toLowerCase(), imgFileTypes);
}


function isMarkdownFile(filename) {
  return isIn(extname(filename).toLowerCase(), mdExts);
}


function isHtmlFile(filename) {
  return isIn(extname(filename).toLowerCase(), htmlExts);
}


// redirect를 5번까지 제한한다.
require('follow-redirects').maxRedirects = 5;
// ##### 원격지의 파일을 다운로드한다.
// - redirect 도 지원한다.
function download(uri, filename) {
  let get;
  const protocol = parseUrl(uri).protocol;
  if(protocol === 'http:') {
    get = http.get;
  } else if(protocol === 'https:') {
    get = https.get;
  } else {
    return Promise.reject(Error('have to http: or https: ' + uri));
  }

  return new Promise(function(resolve, reject) {
    const fileStream = createWriteStream(filename)
      .on('error', reject);
    const request = get(uri, function(res) {
      res.on('end', resolve);
      res.pipe(fileStream);
    });
    request.on('error', reject);
  });
}


// gitnote://auth@repository/pathname.md#hash
// {
//   protocol,
//   auth,
//   repository,
//   pathname,
//   hash,
//   extname
// }
const gitnoteUri = {
  parse(uri) {
    const {protocol, auth, hostname, pathname, hash} = parseUrl(uri);
    if(protocol !== 'gitnote:') {
      return null;
    }
    return {
      protocol,
      auth,
      repository: hostname,
      pathname,
      hash,
      extname: extname(pathname)
    };
  },


  format(format, ignores = []) {
    const ff = {
      protocol: format.protocol,
      auth: format.auth,
      hostname: format.repository,
      pathname: format.pathname,
      hash: format.hash
    };
    for(let ignore of ignores) {
      ff[ignore] = null;
    }
    return formatUrl(ff);
  },


  equal(uri1, uri2) {
    const cUri1 = gitnoteUri.format(gitnoteUri.parse(uri1), ['hash']);
    const cUri2 = gitnoteUri.format(gitnoteUri.parse(uri2), ['hash']);
    return cUri1 === cUri2;
  },


  valid(uri) {
    const parsed = gitnoteUri.parse(uri);
    // gitnote: 프로토콜이어야 한다.
    if(!parsed) {
      return false;
    }
    // 원격지라면 auth와 repository가 있어야하고, 로컬이라면 둘다 없어야 한다.
    if(parsed.auth && !parsed.repository) {
      return false;
    }
    if(!parsed.auth && parsed.repository) {
      return false;
    }
    // 로컬이라면 pathname이 반드시 있어야 한다.
    if(!parsed.auth && !parsed.pathname) {
      return false;
    }
    // 원격이고 pathname이 있다면 pathname은 경로가 없는 순수한 노트 이름이어야 한다.
    if(parsed.auth && parsed.pathname && parsed.pathname.slice(1) !== basename(parsed.pathname)) {
      return false;
    }
    // 노트는 markdown이거나 html이어야 한다.
    if(parsed.pathname && !isMarkdownFile(parsed.pathname) && !isHtmlFile(parsed.pathname)) {
      return false;
    }
    return true;
  },


  isRemote(uri) {
    const {auth, repository} = gitnoteUri.parse(uri);
    return !!(auth && repository);
  },


  isMarkdownFile(uri) {
    const {pathname} = gitnoteUri.parse(uri);
    return isMarkdownFile(pathname);
  },


  isHtmlFile(uri) {
    const {pathname} = gitnoteUri.parse(uri);
    return isHtmlFile(pathname);
  }
};


module.exports = {
  isImageFile,
  isMarkdownFile,
  isHtmlFile,
  download,
  gitnoteUri
};
