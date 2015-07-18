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

# Todos

* [ ] show snippet.  e.g.) when types `graph TD;` , show `A-- foo -->B[bar]\nB-.->C((baz)) `
* [ ] styling. Bigger diagram, font,, etc

# Credits
Many thanks to the [mermaid](https://github.com/knsv/mermaid)  project!
