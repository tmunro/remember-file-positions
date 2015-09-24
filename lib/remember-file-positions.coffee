{CompositeDisposable, TextEditor} = require 'atom'

module.exports = RememberFilePositions =
  subscriptions: null
  fileNumbers: {}

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fileNumbers = state.fileNumbersState ? {}

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        @handleChangeCursorPosition(event)

    @subscriptions.add atom.workspace.onDidAddPaneItem (editor) =>
      @handleAddPaneItem(editor)

  handleAddPaneItem: (editor) ->
    uri = editor.item.getURI()
    currentPosition = editor.item.getCursorBufferPosition()
    if @fileNumbers[uri]? and currentPosition.row == 0
      # We need to know when the editor is actually attached in order to scroll.
      # Otherwise the `lineHeight` of the editor view is 0, and scrolling is impossible.
      view = atom.views.getView(editor.item)
      @subscriptions.add view.onDidAttach =>
        editor.item.setCursorBufferPosition(@fileNumbers[uri], {center: true})

  handleChangeCursorPosition: (event) ->
    @fileNumbers[event.cursor.editor.getURI()] = event.newBufferPosition

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {fileNumbersState: @fileNumbers}
