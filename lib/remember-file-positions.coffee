{CompositeDisposable} = require 'atom'

getView = atom.views.getView.bind(atom.views)

module.exports = RememberFilePositions =
  subscriptions: null
  fileNumbers: {}
  filePositions: {}

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fileNumbers = state.fileNumbersState ? {}
    @filePositions = state.filePositionsState ? {}
    @attachedElements = []

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editorElement = getView(editor)
      uri = editor.getURI()
      {row} = editor.getCursorBufferPosition()
      if @fileNumbers[uri]? and (row in [0, @fileNumbers[uri].row])
        # HACK Atom to scroll to the cursor position of any TextEditors when this package is activated.
        # This is only necessary because Atom incorrectly applies deserialized scroll values.
        @restorePosition(editor)

        # We need to know when the editor is actually attached in order to scroll.
        # Otherwise the `lineHeight` of the editor view is 0, and scrolling is impossible.
        disposable = getView(editor).onDidAttach =>
          disposable.dispose()
          @restorePosition(editor)

      # Preserve scroll position
      @subscriptions.add editorElement.onDidChangeScrollTop =>
        @filePositions[editor.getURI()] =
          top: editorElement.getScrollTop()
          left: editorElement.getScrollLeft()

      # Preserve cursor position
      @subscriptions.add editor.onDidChangeCursorPosition ({newBufferPosition}) =>
        @fileNumbers[editor.getURI()] = newBufferPosition

  restorePosition: (editor) ->
    uri = editor.getURI()
    if (cursorPosition = @fileNumbers[uri])?
      editor.setCursorBufferPosition(cursorPosition)

    if (scrollState = @filePositions[uri])?
      editorElement = getView(editor)
      editorElement.setScrollTop(scrollState.top)
      editorElement.setScrollLeft(scrollState.left)

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {fileNumbersState: @fileNumbers, filePositionsState: @filePositions}
