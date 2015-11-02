# atom-mermaid package

Preview diagrams and flowcharts by mermaid library.

## Installation

In Atom, open [Preferences > Packages], search for `mermaid` package. Once it found, click `Install` button to install package.

### Manual installation

You can install the latest version manually from console:

```bash
cd ~/.atom/packages
git clone https://github.com/y-takey/atom-mermaid
cd atom-mermaid
npm install
```

Then restart Atom editor.

# Usage

`right click and select [Mermaid Preview]`

or

`select menu-bar[Packages -> Mermaid Preview -> Toggle Preview]`

or

<kbd>ctrl</kbd> + <kbd>option</kbd> + <kbd>o</kbd> (Mac)
<kbd>ctrl</kbd> + <kbd>alt</kbd> + <kbd>o</kbd> (Windows probably..)

![atom-mermaid in action](https://github.com/y-takey/atom-mermaid/blob/master/atom-mermaid-example.gif)

About markdown syntax, Please see [Flowchart](http://knsv.github.io/mermaid/flowchart.html) , [Sequence Diagram](http://knsv.github.io/mermaid/sequenceDiagram.html) and [Gantt Diagram](http://knsv.github.io/mermaid/gantt.html)

# Requirements

This package is using native module `node-gyp` . but, there seems to faile to install the module.
If you failed to install, please install the module with reference to the following page.
https://github.com/nodejs/node-gyp

# Todos

* [ ] show snippet.  e.g.) when types `graph TD;` , show `A-- foo -->B[bar]\nB-.->C((baz)) `
* [ ] styling. Bigger diagram, font,, etc

## Contributing

I don't have a deep knowledge of node.js and atom-editor. so, help me!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Credits
Many thanks to the [mermaid](https://github.com/knsv/mermaid)  project!
