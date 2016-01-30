'use babel';

import {extname} from 'path';
import {parse as parseUrl, format as formatUrl} from 'url';
import {createWriteStream} from 'fs';
import {http, https} from 'follow-redirects';



exports.imgFileTypes = [
  '.png',
  '.gif',
  '.jpg',
  '.jpeg',
  '.svg'
];


exports.isImageFile = function(fileName) {
  let isImage = false;
  const ext = extname(fileName).toLowerCase();
  for(let type of exports.imgFileTypes) {
    if(type === ext) {
      isImage = true;
      break;
    }
  }
  return isImage;
};


// redirect를 5번까지 제한한다.
require('follow-redirects').maxRedirects = 5;
// ##### 원격지의 파일을 다운로드한다.
// - redirect 도 지원한다.
exports.download = function (uri, filename) {
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
};

// gitnote://auth@repository/pathname.md#hash
exports.parseGitNoteUri = function(uri) {
  const {protocol, auth, hostname, pathname, hash} = parseUrl(uri);
  if(protocol !== 'gitnote:') {
    return null;
  }
  return {
    protocol,
    auth,
    repository: hostname,
    pathname,
    hash
  };
};


// gitnote://auth@repository/pathname.md#hash
exports.formatGitNoteUri = function(format, ignores = []) {
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
};
