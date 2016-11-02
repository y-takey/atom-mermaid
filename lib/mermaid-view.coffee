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
        'atom-mermaid:save-as-png': (event) =>
          event.stopPropagation()
          @saveAs("png")
        'atom-mermaid:save-as-svg': (event) =>
          event.stopPropagation()
          @saveAs("svg")

      changeHandler = =>
        @renderHTML()
        pane = atom.workspace.paneForURI(@getURI())
        if pane? and pane isnt atom.workspace.getActivePane()
          pane.activateItem(this)

      @editorSub = new CompositeDisposable

      if @editor?
        @editorSub.add @editor.onDidChange _.debounce(changeHandler, 700)
        @editorSub.add @editor.onDidChangePath ->
          atom.commands.dispatch 'atom-mermaid-preview', 'title-changed'

    renderHTML: ->
      @loading = true
      @showLoading()
      @renderHTMLCode() if @editor?
      @loading = false

    renderHTMLCode: (text) ->
      styles = [
        "linkStyle default fill:none,stroke:#0D47A1,stroke-width:2px;"
        "classDef default fill:#B3E5FC,stroke:#0D47A1,stroke-width:2px;"
        "classDef node fill:#B3E5FC,stroke:#0D47A1,stroke-width:2px;"
        "classDef cluster fill:#FFFFDE,stroke:#AAAA33,stroke-width:2px;"
      ]
      mmdText = @editor.getText()
      mmdText = mmdText.replace(
        /(graph (?:TB|TD|LR);*)/g, "$1\n#{styles.join('\n')}")
      div = document.createElement("div")
      div.id = "mmd-tab"
      div.innerHTML = mmdText
      @html $ div
      try
        global.mermaid.parseError = (error, hash)->
          div.innerHTML = error.replace("\n", "<br>")
        global.mermaid.init(undefined, "#mmd-tab")

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

    saveAs: (fileType)->
      return if @loading

      filePath = @getPath()
      title = 'Mermaid to HTML'
      if filePath
        title = path.parse(filePath).name
        filePath += ".#{fileType}"
      else
        filePath = "untitled.mmd.#{fileType}"
        if projectPath = atom.project.getPaths()[0]
          filePath = path.join(projectPath, filePath)

      return unless htmlFilePath = atom.showSaveDialogSync(filePath)

      style = $('style[title="mermaid-svg-internal-css"]')
      styleText = style.text().replace(/\.atom\-mermaid\-preview/g, "")
      style.text(styleText)
      svg = @element.getElementsByTagName("svg")[0]
      svg.innerHTML = svg.innerHTML +
        "<style type='text/css'>.label { color: #000000 !important; } </style>"
      svgData = new XMLSerializer().serializeToString(svg)

      if fileType == "svg"
        @writeFile(htmlFilePath, fileType, svgData)
        return

      canvas = document.createElement("canvas")
      @element.appendChild(canvas)
      svgSize = svg.viewBox.baseVal
      canvas.width = svgSize.width
      canvas.height = svgSize.height
      ctx = canvas.getContext("2d")
      imgsrc = "data:image/svg+xml;charset=utf-8;base64," +
        btoa(unescape(encodeURIComponent(svgData)))
      image = new Image()

      image.onload = ()=>
        # ctx.fillStyle = "#E0F7FA"
        # ctx.fillRect(0, 0, svg.clientWidth, svg.clientHeight)
        ctx.drawImage(image, 0, 0)
        dataUrl = canvas.toDataURL("image/png", 0.9)
        matches = dataUrl.match(/^data:.+\/(.+);base64,(.*)$/)
        buffer = new Buffer(matches[2], 'base64')
        @writeFile(htmlFilePath, fileType, buffer)
        @element.removeChild(canvas)

      image.src = imgsrc

    writeFile: (filePath, fileType, data)->
      fs.writeFileSync(filePath, data)
      atom.notifications.addSuccess "atom-mermaid: Exported a #{fileType} file."
