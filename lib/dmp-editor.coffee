path = require 'path'
{CompositeDisposable} = require 'atom'
resourcePath = atom.config.resourcePath
try
  Editor = require path.resolve resourcePath, 'src', 'editor'
catch e
  # Catch error
TextEditor = Editor ? require path.resolve resourcePath, 'src', 'text-editor'



module.exports =
class DmpEditor extends TextEditor
  constructor: (buffer) ->
    super {
      buffer: buffer
      registerEditor: true
      config: atom.config
      notificationManager: atom.notifications
      packageManager: atom.packages
      clipboard: atom.clipboard
      viewRegistry: atom.views
      grammarRegistry: atom.grammars
      project: atom.project
      assert: atom.assert.bind(atom)
    }
