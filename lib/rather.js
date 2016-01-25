'use babel';

import {extname} from 'path';



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
