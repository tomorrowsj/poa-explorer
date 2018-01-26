import Jasmine from 'jasmine'
import ReactDOM from 'react-dom'

var jasmine = new Jasmine()
jasmine.loadConfigFile('spec/support/jasmine.json')
jasmine.execute()
