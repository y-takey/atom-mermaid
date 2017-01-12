url = require 'url'
{MERMAID_PROTOCOL, MermaidView} = require './mermaid-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomMermaid =
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    @subscriptions = new CompositeDisposable
    @subscriptions.add(
      atom.commands.add('atom-workspace', 'atom-mermaid:toggle': => @toggle()))

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is MERMAID_PROTOCOL

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        new MermaidView(editorId: pathname.substring(1))
      else
        new MermaidView(filePath: pathname)

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    dummy: 'dummy'

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    uri = "#{MERMAID_PROTOCOL}//editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true)
      .then (mermaidView) ->
        if mermaidView instanceof MermaidView
          mermaidView.renderHTML()
          previousActivePane.activate()
