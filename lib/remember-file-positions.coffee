{CompositeDisposable} = require 'atom'

module.exports = RememberFilePositions =
  subscriptions: null
  fileNumbers: {}
  filePositions: {}

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @fileNumbers = state.fileNumbersState ? {}
    @filePositions = state.filePositionsState ? {}

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @handleAddTextEditor(editor)
      @subscriptions.add atom.views.getView(editor).onDidChangeScrollTop (scroll) =>
        @handleChangeScroll(scroll, editor)
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        @handleChangeCursorPosition(event)

  handleAddTextEditor: (editor) ->
    uri = editor.getURI()
    currentPosition = editor.getCursorBufferPosition()

    if @fileNumbers[uri]? and (currentPosition.row is 0 or currentPosition.row is @fileNumbers[uri].row)
      # There is the situation when editorElement.getScrollTop() return 0 but
      # editorElement.component.getScrollTop return underfined.
      # In this case, setting setScrollTop via editorElement.setScrollTop()
      # cause editor blank on subsequent pane-split.
      # In other word, editorElement.getScrollTop is NOT beliebable, this is why we need to check
      # component.getScrollTop() return valid value before trying to setScrollTop.
      view = atom.views.getView(editor)
      if view.component.getScrollTop()?
        @setCursorAndScroll(editor, uri)
      else
        disposable = view.onDidChangeScrollTop =>
          disposable.dispose()
          disposable = null
          @setCursorAndScroll(editor, uri)

  setCursorAndScroll: (editor, uri) ->
    position = @filePositions[uri]
    editor.setCursorBufferPosition(@fileNumbers[uri])
    if position?
      view = atom.views.getView(editor)
      view.setScrollTop(position.top)
      view.setScrollLeft(position.left)

  handleChangeCursorPosition: (event) ->
    @fileNumbers[event.cursor.editor.getURI()] = event.newBufferPosition

  handleChangeScroll: (scroll, editor) ->
    # editor.displayBuffer.pixelPositionForScreenPosition(position)
    view = atom.views.getView(editor)
    screenPosition = {top: view.getScrollTop(), left: view.getScrollLeft()}
    @filePositions[editor.getURI()] = screenPosition

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {fileNumbersState: @fileNumbers, filePositionsState: @filePositions}
