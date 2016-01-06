AtomGitNote = require '../lib/atom-gitnote'
fs = require 'fs-extra'
path = require 'path'
nodegit = require 'nodegit'
$4 = require '../lib/fourdollar'
$4.debug()
GitNote = require '../lib/lib-gitnote'

fs.remove = $4.makePromise(fs.remove)
fs.ensureDir = $4.makePromise(fs.ensureDir)


# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "atom.GitNote", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-gitnote')

  describe "when the atom-gitnote:toggle-find event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.atom-gitnote')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.atom-gitnote')).toExist()
        atomGitNoteElement = workspaceElement.querySelector('.atom-gitnote')
        expect(atomGitNoteElement).toExist()
        atomGitnotePanel = atom.workspace.panelForItem(atomGitNoteElement)
        expect(atomGitnotePanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'
        expect(atomGitnotePanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.atom-gitnote')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        atomGitNoteElement = workspaceElement.querySelector('.atom-gitnote')
        expect(atomGitNoteElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'atom-gitnote:toggle-find'
        expect(atomGitNoteElement).not.toBeVisible()
