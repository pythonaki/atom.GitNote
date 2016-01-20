'use babel';

import {resolve, dirname, basename} from 'path';
import {parse as parseUrl} from 'url';
import {exists} from 'fs';
import $4 from './fourdollar';
import marked from 'marked';
import {createImageName} from './lib-gitnote';


const fsExists = $4.makePromise(exists, false);


module.exports = MarkdownEditor = function(editor) {
  editor.getTitle = function() {
    let title = null;
    const renderer = new marked.Renderer();
    renderer.heading = (text, level) => {
      if(!title) {
        title = text;
      }
    };
    marked.parse(this.getText(), {renderer});
    if(title) {
      return `# ${title}`;
    } else {
      return '# untitled';
    }
  }.bind(editor);


  editor.getLongTitle = function() {
    `${this.getTitle()} - ${basename(this.buffer.getPath())}`;
  }.bind(editor);


  editor.save = function() {
    console.log('MarkdownEditor#save()');
    const imgs = [];
    const renderer = new marked.Renderer();
    renderer.image = (href, title, text) => {
      const {protocol} = parseUrl(href);
      if(protocol && (protocol === 'http:' || protocol === 'https:')) {
        const filePath = resolve(dirname(this.getPath())
          , createImageName(href));
        imgs.push(fsExists(filePath)
          .then((exists) => {
            if(!exists) {
              return $4.download(href, filePath);
            }
          })
        );
      }
    }

    marked.parse(this.getText(), {renderer: renderer});

    return Promise.all(imgs)
    .then(() => {
      this.buffer.save();
      this.emitter.emit('did-change-title', this.getTitle());
      this.emitter.emit('saved', {target: this});
      return this;
    });
  }.bind(editor);


  editor.saveAs = function(filePath) {
    msg = "Don't allow saveAs!!";
    console.error(msg);
  }.bind(editor);


  // getBuff? 와 getPath? 로 gitnote와 관계된 pane인지 확인.
  editor.getBuff = editor.getBuffer;

  editor.emitter.emit('did-change-title', editor.getTitle());
};
