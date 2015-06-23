AtomMermaidView = require './atom-mermaid-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomMermaid =
  atomMermaidView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomMermaidView = new AtomMermaidView(state.atomMermaidViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomMermaidView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mermaid:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomMermaidView.destroy()

  serialize: ->
    atomMermaidViewState: @atomMermaidView.serialize()

  toggle: ->
    console.log 'AtomMermaid was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
