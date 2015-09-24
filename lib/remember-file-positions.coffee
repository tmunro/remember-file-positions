{CompositeDisposable, TextEditor} = require 'atom'

module.exports = RememberFilePositions =
  subscriptions: null
  fileNumbers: {}
  filePositions: {}

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fileNumbers = state.fileNumbersState ? {}
    @filePositions = state.filePositionsState ? {}

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        @handleChangeCursorPosition(event)

    @subscriptions.add atom.workspace.onDidAddTextEditor (event) =>
      @handleAddTextEditor(event)

  handleAddTextEditor: (event) ->
    uri = event.textEditor.getURI()

    @subscriptions.add event.textEditor.onDidChangeScrollTop (scroll) =>
      @handleChangeScroll(scroll, uri)

    currentPosition = event.textEditor.getCursorBufferPosition()
    if @fileNumbers[uri]? and currentPosition.row == 0
      # We need to know when the editor is actually attached in order to scroll.
      # Otherwise the `lineHeight` of the editor view is 0, and scrolling is impossible.
      view = atom.views.getView(event.textEditor)
      @subscriptions.add view.onDidAttach =>
        position = @filePositions[uri]
        event.textEditor.setCursorBufferPosition(@fileNumbers[uri])
        if position?
          event.textEditor.setScrollTop(position)

  handleChangeCursorPosition: (event) ->
    @fileNumbers[event.cursor.editor.getURI()] = event.newBufferPosition

  handleChangeScroll: (scroll, uri) ->
    @filePositions[uri] = scroll

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {fileNumbersState: @fileNumbers, filePositionsState: @filePositions}
