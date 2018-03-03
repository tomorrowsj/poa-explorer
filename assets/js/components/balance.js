import React from 'react'

export default class Balance extends React.Component {
  constructor (props) {
    super(props)
    this.state = {balance: '...'}
  }

  componentDidMount () {
    const that = this
        const body = {
      "jsonrpc":"2.0",
      "method":"eth_getBalance",
      "params":[
        this.props.address,
        "latest"
      ],
      "id":1
    }
    fetch(this.props.parity_host, {
      method: "POST",
      body: JSON.stringify(body)
    }).then((res) => res.json())
    .then((res) => {
      console.log(res)
      const balance = parseInt(res.result) / 10e17
      this.setState({balance: balance})
    })
  }

  render () {
    return <span>{this.state.balance}</span>
  }
}
