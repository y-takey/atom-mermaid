path                  = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
_                     = require 'underscore-plus'
fs                    = require 'fs-plus'
# Work around: references window object in dagre-d3/lib/d3.js
d3                    = require 'd3'
window.d3 = d3
{mermaidAPI} = require 'mermaid/dist/mermaid'

module.exports =
  MERMAID_PROTOCOL: "mermaid-preview:"
  MermaidView: class MermaidView extends ScrollView

    atom.deserializers.add(this)

    editorSub           : null
    onDidChangeTitle    : -> new Disposable()
    onDidChangeModified : -> new Disposable()

    @deserialize: (state) ->
      new MermaidView(state)

    @content: ->
      @div class: 'atom-mermaid-preview native-key-bindings', tabindex: -1

    constructor: ({@editorId, filePath}) ->
      super

      if @editorId?
        @resolveEditor(@editorId)
      else
        if atom.workspace?
          @subscribeToFilePath(filePath)
        else
          atom.packages.onDidActivatePackage =>
            @subscribeToFilePath(filePath)

    serialize: ->
      deserializer : 'MermaidView'
      filePath     : @getPath()
      editorId     : @editorId

    destroy: ->
      @editorSub.dispose()

    subscribeToFilePath: (filePath) ->
      atom.commands.dispatch 'atom-mermaid-preview', 'title-changed'
      @handleEvents()
      @renderHTML()

    resolveEditor: (editorId) ->
      resolve = =>
        @editor = @editorForId(editorId)

        if @editor?
          atom.commands.dispatch 'atom-mermaid-preview', 'title-changed'
          @handleEvents()
        else
          atom.workspace?.paneForItem(this)?.destroyItem(this)

      if atom.workspace?
        resolve()
      else
        atom.packages.onDidActivatePackage =>
          resolve()
          @renderHTML()

    editorForId: (editorId) ->
      for editor in atom.workspace.getTextEditors()
        return editor if editor.id?.toString() is editorId.toString()
      null

    handleEvents: =>
      atom.commands.add @element,
        'atom-mermaid:save-as': (event) =>
          event.stopPropagation()
          @saveAs()
        'atom-mermaid:copy': (event) =>
          event.stopPropagation() if @copyToClipboard()

      changeHandler = =>
        @renderHTML()
        pane = atom.workspace.paneForURI(@getURI())
        if pane? and pane isnt atom.workspace.getActivePane()
          pane.activateItem(this)

      @editorSub = new CompositeDisposable

      if @editor?
        @editorSub.add @editor.onDidChange _.debounce(changeHandler, 700)
        @editorSub.add @editor.onDidChangePath =>
          atom.commands.dispatch 'atom-mermaid-preview', 'title-changed'

    renderHTML: ->
      @loading = true
      @showLoading()
      @renderHTMLCode() if @editor?
      @loading = false

    renderHTMLCode: (text) ->
      mmdText = @editor.getText()
      div = document.createElement("div")
      div.id = "mmd-tab"
      div.innerHTML = mmdText
      @html $ div
      try
        mermaid.parseError = (error, hash)->
          div.innerHTML = error.replace("\n", "<br>")
        mermaid.init(undefined, "#mmd-tab")

    getTitle: ->
      if @editor?
        "#{@editor.getTitle()} Preview"
      else
        "Mermaid Preview"

    getURI: ->
      "mermaid-preview://editor/#{@editorId}"

    getPath: ->
      @editor.getPath() if @editor?

    showError: (result) ->
      failureMessage = result?.message

      @html $$$ ->
        @h2 'Previewing Mermaid Failed!!'
        @h3 failureMessage if failureMessage?

    showLoading: ->
      @html $$$ ->
        @div class: 'atom-html-spinner', 'Loading Mermaid Preview\u2026'

    copyToClipboard: ->
      return false if @loading

      selection = window.getSelection()
      selectedText = selection.toString()
      selectedNode = selection.baseNode

      # Use default copy event handler if there is selected text inside this view
      return false if selectedText and selectedNode? and (@[0] is selectedNode or $.contains(@[0], selectedNode))

      @getHTML (error, html) ->
        if error?
          console.warn('Copying Markdown as HTML failed', error)
        else
          atom.clipboard.write(html)

      true

    saveAs: ->
      return if @loading

      filePath = @getPath()
      title = 'Mermaid to HTML'
      if filePath
        title = path.parse(filePath).name
        filePath += '.png'
      else
        filePath = 'untitled.mmd.png'
        if projectPath = atom.project.getPaths()[0]
          filePath = path.join(projectPath, filePath)

      return unless htmlFilePath = atom.showSaveDialogSync(filePath)

      svg = @element.getElementsByTagName("svg")[0]
      svgData = new XMLSerializer().serializeToString(svg)
      canvas = document.createElement("canvas")
      @element.appendChild(canvas)
      canvas.width = svg.clientWidth
      canvas.height = svg.clientHeight
      ctx = canvas.getContext("2d")
      imgsrc = "data:image/svg+xml;charset=utf-8;base64," + btoa(unescape(encodeURIComponent(svgData)))
      image = new Image()

      image.onload = ()=>
        ctx.drawImage(image, 0, 0);
        dataUrl = canvas.toDataURL("image/png", 0.9)
        matches = dataUrl.match(/^data:.+\/(.+);base64,(.*)$/)
        buffer = new Buffer(matches[2], 'base64')
        fs.writeFileSync(htmlFilePath, buffer)
        @element.removeChild(canvas)
        atom.notifications.addSuccess "atom-mermaid: Exported a PNG file."

      image.src = imgsrc;
