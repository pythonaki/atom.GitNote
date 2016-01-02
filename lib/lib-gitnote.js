'use strict';

var _slicedToArray = (function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; })();

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })(); // babel
//

var _nodegit = require('nodegit');

var _nodegit2 = _interopRequireDefault(_nodegit);

var _marked = require('marked');

var _marked2 = _interopRequireDefault(_marked);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _fsExtra = require('fs-extra');

var _fsExtra2 = _interopRequireDefault(_fsExtra);

var _fourdollar = require('../lib/fourdollar');

var _fourdollar2 = _interopRequireDefault(_fourdollar);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { return obj && typeof Symbol !== "undefined" && obj.constructor === Symbol ? "symbol" : typeof obj; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

_fourdollar2.default.node();
_fourdollar2.default.unique();

'use strict';

_fsExtra2.default.ensureDir = _fourdollar2.default.makePromise(_fsExtra2.default.ensureDir);
_fsExtra2.default.ensureFile = _fourdollar2.default.makePromise(_fsExtra2.default.ensureFile);
_fsExtra2.default.copy = _fourdollar2.default.makePromise(_fsExtra2.default.copy);
_fsExtra2.default.exists = _fourdollar2.default.makePromise(_fsExtra2.default.exists, false);
_fsExtra2.default.readdir = _fourdollar2.default.makePromise(_fsExtra2.default.readdir);
_fsExtra2.default.readFile = _fourdollar2.default.makePromise(_fsExtra2.default.readFile);
_fsExtra2.default.writeFile = _fourdollar2.default.makePromise(_fsExtra2.default.writeFile);
_fsExtra2.default.stat = _fourdollar2.default.makePromise(_fsExtra2.default.stat);

var GitNote = (function () {
  _createClass(GitNote, null, [{
    key: 'env',
    get: function get() {
      return {
        GITHUB_PAGES: 'gh-pages',
        NOTE_DIRNAME: 'notes',
        ABLE_EXTS: ['.md'],
        DIC_FILENAME: 'dictionary.json'
      };
    }
  }]);

  function GitNote(repository, dictionary, options) {
    _classCallCheck(this, GitNote);

    this._repo = repository;
    this._opts = options;
    this._dic = dictionary;
    this._unpackedDic = null;
  }

  _createClass(GitNote, [{
    key: 'dictionary',
    value: function dictionary() {
      var _this = this;

      return this.update().then(function (updated) {
        if (!_this._unpackedDic) {
          var dics = [];
          // for(let item of this._dic.values()) {
          //   dics.push(item);
          // }
          for (var key in _this._dic) {
            dics.push(_this._dic[key]);
          }
          _this._unpackedDic = Array.prototype.concat.apply([], dics);
        }
        return _this._unpackedDic;
      });
    }
  }, {
    key: 'create',
    value: function create(ext) {
      var id = GitNote._createId();
      return this.getNotePath(id, id + '.' + ext);
    }
  }, {
    key: 'getNotePath',
    value: function getNotePath() {
      var args = Array.prototype.slice.call(arguments);
      return _path2.default.resolve.apply(null, [this._repo.workdir(), GitNote.env.NOTE_DIRNAME].concat(args));
    }
  }, {
    key: 'update',
    value: function update() {
      var _this2 = this;

      var repo = this._repo;
      var opts = this._opts;

      return GitNote._checkoutBranch(repo, GitNote.env.GITHUB_PAGES).then(function () {
        return repo.getHeadCommit();
      }).then(function (head) {
        if (head.sha() !== _this2.headSha) {
          return GitNote._openDic(repo).then(function (dic) {
            _this2._dic = dic;
            _this2._unpackedDic = null;
            _this2._modMap = new Map();
            _this2.headSha = head.sha();
          });
        }
      }).then(function () {
        return _this2.updateDictionary();
      });
    }
  }, {
    key: 'updateDictionary',
    value: function updateDictionary() {
      var _this3 = this;

      return this._repo.getStatus().then(function (statuses) {
        var filters = statuses.filter(function (status) {
          return GitNote._isNoteFile(status.path());
        });
        return _this3._isChangedFiles(filters);
      }).then(function (changeds) {
        if (changeds.size !== 0) {
          return _this3._modifyDic(changeds)
          // .then(() => {
          //   return this._saveDic();
          // })
          .then(function () {
            _this3._unpackedDic = null;
            return true;
          });
        } else {
          return false;
        }
      });
    }
  }, {
    key: 'push',
    value: function push() {
      var _this4 = this;

      return this.update().then(function () {
        return _this4._repo.getStatus();
      }).then(function (statuses) {
        var some = statuses.some(function (status) {
          return GitNote._isNoteFile(status.path());
        });
        if (some) {
          return GitNote._saveDic(_this4._repo, _this4._dic).then(function () {
            return GitNote._createCommit(_this4._repo, _this4._opts.author, _this4._opts.committer, new Date().toLocaleString());
          }).then(function () {
            return true;
          });
        } else {
          return false;
        }
      });
    }
  }, {
    key: '_isChangedFiles',

    // 현재 커밋에 달라진 파일들 추출.
    value: function _isChangedFiles(statuses) {
      var _this5 = this;

      var modMap = new Map(this._modMap);
      this._modMap = new Map();
      var thisModMap = this._modMap;
      var diffMap = new Map();
      var promises = statuses.map(function (status) {
        var id = _path2.default.basename(status.path(), _path2.default.extname(status.path()));
        var mod = modMap.get(id);
        modMap.delete(id);
        if (status.isDeleted()) {
          thisModMap.set(id, { id: id, file: status.path(), isDeleted: true, mtime: 0 });
          // 기존 맵에 없거나 isDeleted가 아니었다면..
          if (!mod || !mod.isDeleted) {
            diffMap.set(id, thisModMap.get(id));
          }
          return null;
        } else {
          return _fsExtra2.default.stat(_path2.default.resolve(_this5._repo.workdir(), status.path())).then(function (state) {
            thisModMap.set(id, { id: id, file: status.path(), isDeleted: false, mtime: state.mtime.getTime() });
            // 기존 맵에 없거나 mtime이 다르다면..
            if (!mod || mod.mtime !== state.mtime.getTime()) {
              if (mod) {}
              diffMap.set(id, thisModMap.get(id));
            }
          });
        }
      });
      promises = promises.filter(function (promise) {
        return !!promise;
      });

      return Promise.all(promises).then(function () {
        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          for (var _iterator = modMap.entries()[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var _step$value = _slicedToArray(_step.value, 2);

            var id = _step$value[0];
            var val = _step$value[1];

            diffMap.set(id, val);
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator.return) {
              _iterator.return();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }

        return diffMap;
      });
    }
  }, {
    key: '_modifyDic',
    value: function _modifyDic(map) {
      var _this6 = this;

      var modFiles = [];
      var promises = [];
      map.forEach(function (item) {
        var file = _path2.default.resolve(_this6._repo.workdir(), item.file);
        promises.push(_fsExtra2.default.exists(file).then(function (exists) {
          if (exists) {
            modFiles.push(file);
          } else {
            delete _this6._dic[item.id];
          }
        }));
      });

      return Promise.all(promises).then(function () {
        return GitNote._addDic(_this6._dic, modFiles);
      }).then(function (dic) {
        _this6._dic = dic;
        return dic;
      });
    }
  }, {
    key: 'repository',
    get: function get() {
      return this._repo;
    }
  }], [{
    key: 'wasInited',
    value: function wasInited(repoPath) {
      return _nodegit2.default.Repository.open(_path2.default.resolve(repoPath, './.git')).then(function (repo) {
        return !!repo;
      }).catch(function (e) {
        return false;
      });
    }
  }, {
    key: 'create',
    value: function create(repoPath, options) {
      var repo;
      var author;
      var committer;
      var opts = options ? options : {};

      return _fsExtra2.default.ensureDir(repoPath).then(function () {
        return _fsExtra2.default.readdir(repoPath);
      }).then(function (files) {
        if (files.length !== 0) {
          return Promise.reject(Error('이미 경로가 존재하여 Repository를 만들수 없다.'));
        }
      }).then(function () {
        return _fsExtra2.default.ensureDir(_path2.default.resolve(repoPath, GitNote.env.NOTE_DIRNAME));
      })
      // git init
      .then(function () {
        return _nodegit2.default.Repository.init(repoPath, 0);
      })
      // Repository, Signature 저장.
      .then(function (repo_) {
        repo = repo_;
        author = GitNote._getSignature(repo, opts.author);
        committer = GitNote._getSignature(repo, opts.committer);

        // HEAD 만들기.
        return GitNote._createCommit(repo, author, committer, 'commit for gh-pages');
      })
      // gh-pages branch 생성.
      .then(function (oid) {
        return GitNote._createBranch(repo, GitNote.env.GITHUB_PAGES);
      })
      // checkout tmp-branch
      .then(function (ref) {
        return repo.checkoutBranch(GitNote.env.GITHUB_PAGES);
      }).then(function () {
        return new GitNote(repo, {}, { author: author, committer: committer, committer: committer });
      });
    }
  }, {
    key: 'open',
    value: function open(repoPath, options) {
      var gitNote;

      return _nodegit2.default.Repository.open(_path2.default.resolve(repoPath, '.git')).then(function (repo) {
        var opts = options ? options : {};
        var author = GitNote._getSignature(repo, opts.author);
        var committer = GitNote._getSignature(repo, opts.committer);
        return new GitNote(repo, {}, { author: author, committer: committer });
      });
    }
  }, {
    key: '_openDic',
    value: function _openDic(repo) {
      var dicPath = _path2.default.resolve(repo.workdir(), GitNote.env.DIC_FILENAME);

      return _fsExtra2.default.exists(dicPath).then(function (exists) {
        if (exists) {
          return _fsExtra2.default.readFile(dicPath, { encoding: 'utf-8' }).then(JSON.parse);
        } else {
          var _ret = (function () {
            var notePath = _path2.default.resolve(repo.workdir(), GitNote.env.NOTE_DIRNAME);
            return {
              v: _fsExtra2.default.readdir(notePath).then(function (files) {
                var noteFiles = files.map(function (name) {
                  return _fsExtra2.default.stat(_path2.default.resolve(notePath, name)).then(function (stats) {
                    if (stats.isDirectory()) {
                      return _fsExtra2.default.readdir(_path2.default.resolve(notePath, name)).then(function (items) {
                        var ables = items.filter(function (item) {
                          return GitNote._isNoteFile(_path2.default.resolve(notePath, name, item));
                        });
                        return ables.length !== 0 ? _path2.default.resolve(notePath, name, ables[0]) : null;
                      });
                    } else {
                      return null;
                    }
                  });
                });
                return Promise.all(noteFiles);
              }).then(function (noteFiles) {
                noteFiles = noteFiles.filter(function (file) {
                  return file;
                });
                // return GitNote._addDic(new Map(), noteFiles);
                return GitNote._addDic({}, noteFiles).then(function (dic) {
                  return GitNote._saveDic(repo, dic).then(function () {
                    return dic;
                  });
                });
              })
            };
          })();

          if ((typeof _ret === 'undefined' ? 'undefined' : _typeof(_ret)) === "object") return _ret.v;
        }
      });
    }
  }, {
    key: '_addDic',
    value: function _addDic(dic, noteFiles) {
      var getDicItems = noteFiles.map(function (noteFile) {
        return _fsExtra2.default.readFile(noteFile, { encoding: 'utf-8' }).then(function (content) {
          var renderer = new _marked2.default.Renderer();
          var file = _path2.default.basename(noteFile);
          var id = _path2.default.basename(file, _path2.default.extname(file));
          var levelHeads = [];
          var dicItem = [];
          renderer.heading = function (text, level) {
            for (var i = level; i < 6; i++) {
              levelHeads[i] = null;
            }
            levelHeads[level - 1] = text;
            dicItem.push({
              id: id,
              file: file,
              headId: _fourdollar2.default.sha1(text),
              level: level,
              headline: (dicItem.length == 0 ? '' : GitNote._indent(level)) + text,
              fullHeadline: levelHeads.filter(function (head) {
                return head;
              }).join(' - ')
            });
          };
          (0, _marked2.default)(content, {
            renderer: renderer
          });
          // dic.set(id, dicItem);
          dic[id] = dicItem;
        });
      });

      return Promise.all(getDicItems).then(function () {
        return dic;
      });
    }
  }, {
    key: '_indent',
    value: function _indent(level) {
      var indent = '';
      for (var i = 1; i < level; i++) {
        indent += ' ';
      }
      return indent;
    }
  }, {
    key: '_createBranch',
    value: function _createBranch(repo, branchName) {
      return repo.getHeadCommit().then(function (commit) {
        return repo.createBranch(branchName, commit);
      });
    }
  }, {
    key: '_createCommit',
    value: function _createCommit(repo, author, committer, message) {
      return repo.openIndex().then(function (index) {
        return index.addAll().then(function () {
          index.write();
          return index.writeTree();
        });
      }).then(function (oid) {
        return _fourdollar2.default.delivery(repo.getHeadCommit(), 'parent', { oid: oid });
      }).then(function (args) {
        var oid = args.oid;
        var parent = args.parent;

        var parents = parent ? [parent] : [];
        return repo.createCommit('HEAD', author, committer, message, oid, parents);
      });
    }
  }, {
    key: '_checkoutBranch',
    value: function _checkoutBranch(repo, name) {
      return repo.getCurrentBranch().then(function (branch) {
        if (branch.name() !== 'refs/heads/' + name) {
          return repo.checkoutBranch(name);
        }
        return branch;
      });
    }
  }, {
    key: '_getSignature',
    value: function _getSignature(repo, sig) {
      if (sig) {
        return _nodegit2.default.Signature.now(sig.name, sig.email);
      } else {
        return _nodegit2.default.Signature.default(repo);
      }
    }
  }, {
    key: '_isNoteFile',
    value: function _isNoteFile(notePath) {
      var dirname = _path2.default.dirname(notePath);
      dirname = dirname.split(_path2.default.sep);
      var noteIndex = dirname.indexOf(GitNote.env.NOTE_DIRNAME);
      if (noteIndex === -1) {
        return null;
      }
      dirname = dirname[noteIndex + 1];
      if (dirname === _path2.default.basename(notePath, _path2.default.extname(notePath)) && GitNote.env.ABLE_EXTS.some(function (item) {
        return item === _path2.default.extname(notePath);
      })) {
        return notePath;
      }
      return null;
    }
  }, {
    key: '_createId',
    value: function _createId() {
      return _fourdollar2.default.timeNow(16) + _fourdollar2.default.randomID(16);
    }
  }, {
    key: '_saveDic',
    value: function _saveDic(repo, dic) {
      var dicPath = _path2.default.resolve(repo.workdir(), GitNote.env.DIC_FILENAME);
      return _fsExtra2.default.writeFile(dicPath, JSON.stringify(dic), { encoding: 'utf-8' });
    }
  }]);

  return GitNote;
})();

module.exports = GitNote;
//# sourceMappingURL=lib-gitnote.js.map
