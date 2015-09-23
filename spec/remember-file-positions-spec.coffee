RememberFilePositions = require '../lib/remember-file-positions'
{Point} = require 'atom'

describe "RememberFilePositions", ->
  [rememberFilePositions, workspaceElement, fixturesPath, fixture] = []

  beforeEach ->
    fixturesPath = atom.project.getPaths()[0]
    fixture = fixturesPath + '/test.js'

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.packages.activatePackage('remember-file-positions').then (pack) ->
        rememberFilePositions = pack.mainModule

  describe "when a file is opened", ->
    describe "and there is an entry for that file's URI", ->
      beforeEach ->
        rememberFilePositions.fileNumbers[fixture] = new Point(169, 9)
        waitsForPromise ->
          atom.workspace.open('test.js')

      it "moves the cursor position to the saved position and scrolls the view", ->
        item = atom.workspace.getActivePaneItem()

        waitsFor "editor to attach", 1000, ->
          item.getLineHeightInPixels() > 0

        runs ->
          expect(item.getCursorBufferPosition().row).toBe 169
          expect(item.getCursorBufferPosition().column).toBe 9
          # I don't know how to set the size of the spec window smaller in order to force scrolling.
          # expect(item.displayBuffer.getScrollTop()).toBe 100

    describe "and there is no entry for that file's URI", ->
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open('test.js')

      it "does not change the cursor position", ->
        item = atom.workspace.getActivePaneItem()

        waitsFor "editor to attach", 1000, ->
          item.getLineHeightInPixels() > 0

        runs ->
          expect(item.getCursorBufferPosition().row).toBe 0
          expect(item.getCursorBufferPosition().column).toBe 0

    describe "and a line number is specified", ->
      it "does not change the cursor position", ->
      beforeEach ->
        rememberFilePositions.fileNumbers[fixture] = new Point(169, 9)
        waitsForPromise ->
          atom.workspace.open('test.js', {initialLine: 10})

      it "does not change the cursor position", ->
        item = atom.workspace.getActivePaneItem()

        waitsFor "editor to attach", 1000, ->
          item.getLineHeightInPixels() > 0

        runs ->
          expect(item.getCursorBufferPosition().row).toBe 10
          expect(item.getCursorBufferPosition().column).toBe 0

  describe "when an editor's cursor position changes", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(fixture)

    it "stores the new cursor position for that editor", ->
      item = atom.workspace.getActivePaneItem()
      
      expect(item.getCursorBufferPosition().row).toBe 0
      item.setCursorBufferPosition(new Point(169, 9))
      expect(rememberFilePositions.fileNumbers[fixture].row).toBe 169
