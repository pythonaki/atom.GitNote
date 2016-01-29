'use babel';

import {resolve, dirname, basename, extname} from 'path';
import {parse as parseUrl} from 'url';
import {exists, copy, ensureDir, copySync} from 'fs-extra';
import $4 from './fourdollar';
$4.node();
import {isImageFile, download} from './rather';
import marked from 'marked';
import {getId, createName, createRandomName} from './lib-gitnote';
import {CompositeDisposable} from 'atom';


const fsExists = $4.makePromise(exists, false);
const fsCopy = $4.makePromise(copy);
const fsEnsureDir = $4.makePromise(ensureDir);


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
    } else if(this.getPath()) {
      return `# ${basename(this.getPath())}`;
    } else {
      return '# untitled';
    }
  };


  editor.getLongTitle = function() {
    return `${this.getTitle()} - ${basename(this.buffer.getPath())}`;
  };


  editor.save = function() {
    console.log('MarkdownEditor#save()');
    if(!this.isModified()) {
      return;
    }
    const imgs = [];
    const renderer = new marked.Renderer();
    renderer.image = (href, title, text) => {
      const {protocol, host} = parseUrl(href);
      if(protocol && (protocol === 'http:' || protocol === 'https:') && isImageFile(href)) {
        const filePath = resolve(dirname(this.getPath())
          , createName(this.getId(), href));
        this.savingSet.add(fsExists(filePath)
          .then((exists) => {
            if(!exists) {
              return fsEnsureDir(dirname(this.getPath()))
              .then(() => {
                return download(href, filePath);
              });
            }
          })
        );
      }
    };

    marked.parse(this.getText(), {renderer: renderer});
    return Promise.all(Array.from(this.savingSet))
    .then(() => {
      this.buffer.save();
      this.initSavingSet();
      this.emitter.emit('did-change-title', this.getTitle());
      // this.emitter.emit('saved', {target: this});
      this.emitter.emit('success', {target: this, message: 'saved!!'});
      return this;
    })
    .catch((err) => {
      this.initSavingSet();
      msg = (err.stack)? err.stack : err;
      this.emitter.emit('error', {target: this, message: msg});
      return null;
    });
  };


  editor.saveAs = function(filePath) {
    msg = "Don't allow saveAs!!";
    console.error(msg);
  };


  editor.getElement = function() {
    return atom.views.getView(this);
  };


  editor.insertImage = function() {
    console.log('MarkdownEditor#insertImage()');
    const event = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      view: window
    });
    this.imgDialog.dispatchEvent(event);
  };


  editor.getId = function() {
    return getId(this.getPath());
  };


  editor.initSavingSet = function() {
    if(!this.savingSet) {
      this.savingSet = new Set();
    } else {
      this.savingSet.clear();
    }
  };


  editor.addSavingFile = function(filePath) {
    if(this.savingSet.size === 0) {
      this.savingSet.add(fsEnsureDir(dirname(this.getPath())));
    }
    const imgFileName = createRandomName(this.getId()) + extname(filePath);
    this.insertText(
      `![${basename(filePath)}](${imgFileName})\n`);
    this.savingSet.add(
      $4.copy(filePath, resolve(dirname(this.getPath()), imgFileName)));
    return imgFileName;
  };


  editor.onSuccess = function(callback) {
    return this.emitter.on('success', callback);
  };


  editor.onError = function(callback) {
    return this.emitter.on('error', callback);
  };


  editor.onDidDestroy(function() {
    console.log('MarkdownEditor#onDidDestroy()');
    editor.disposables.dispose();
  });

  editor.disposables = new CompositeDisposable();
  editor.disposables.add(atom.commands.add(editor.getElement()
    , {'atom-gitnote:insert-image': function() { this.insertImage(); }.bind(editor)}));

  editor.getElement().innerHTML += '<div class="gitnote-dialog-contain" style="display:none"></div>';
  const contain = editor.getElement().querySelector('.gitnote-dialog-contain');
  contain.innerHTML = '<input class="gitnote-img-dialog" type="file" accept="image/*" />'
  editor.imgDialog = contain.querySelector('.gitnote-img-dialog');
  editor.imgDialog.addEventListener('change', function(evt) {
    const file = evt.target.files[evt.target.files.length - 1];
    if(file) {
      this.addSavingFile(file.path);
    }
  }.bind(editor));


  // getBuff? 와 getPath? 로 gitnote와 관계된 pane인지 확인.
  editor.getBuff = editor.getBuffer;
  editor.initSavingSet();

  editor.emitter.emit('did-change-title', editor.getTitle());
  return editor
};
