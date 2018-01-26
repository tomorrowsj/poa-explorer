import React from 'react'
import ReactDOM from 'react-dom'
import {JSDOM} from 'jsdom'

import Blocks from '../../js/components/blocks'

describe('blocks', () => {
  let root, dom

  beforeEach(() => {
    dom = new JSDOM('<div id="jasmine_content"></div>')
    root = dom.window.document.getElementById('jasmine_content')
    ReactDOM.render(<Blocks/>, root)
  })

  it('renders the blocks component on the page', () => {
    console.log(root.querySelector("#text"))
    expect(root.querySelector("#text").innerText).toContain('Barf')
  })
})
