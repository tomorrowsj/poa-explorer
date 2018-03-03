import React from 'react'
import ReactDOM from 'react-dom'

import Balance from '../../js/components/balance'

describe('Balance', () => {
  describe('render', () => {
    beforeEach(() => {
      const response = {
        json: function() {
          return new Promise(function(resolve, reject) {
            resolve({"jsonrpc":"2.0","result":"0x51c474548f46da0","id":1})
          })
        }
      }

      const res = new Promise((resolve, reject) => resolve(response))

      spyOn(window, 'fetch').and.returnValue(res)
    })

    it('displays the balance', (done) => {
      const target = document.querySelector('#jasmine_content')
      const props = {parity_host: "http://localhost:4000", address: "0xdd0bb0e2a1594240fed0c2f2c17c1e9ab4f87126"}
      const component = React.createElement(Balance, props)
      ReactDOM.render(component, target)
      setTimeout(() => {
        expect(target.innerHTML).toBe('<span>0.368247632439832</span>')
        done()
      }, 1000)
    })
  })
})
