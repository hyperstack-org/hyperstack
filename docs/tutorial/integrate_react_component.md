# Integrate Javascript Libraries with HyperStack: The ReactDatePicker case

## TL;DR

## assumpitons

## yarn package installation

https://momentjs.com/

https://reactdatepicker.com/
https://github.com/Hacker0x01/react-datepicker/

yarn add moment react-datepicker

yarn

### package.json
```json
{
  "name": "react-datepicker-demo",
  "private": true,
  "dependencies": {
    "@rails/webpacker": "3.5",
    "babel-preset-react": "^6.24.1",
    "bootstrap": "^4.1.3",
    "caniuse-lite": "^1.0.30000883",
    "history": "^4.7.2",
    "immutable": "^3.8.2",
    "jquery": "^3.3.1",
    "jquery-ujs": "^1.2.2",
    "moment": "^2.22.2",
    "popper.js": "^1.14.4",
    "prop-types": "^15.6.2",
    "react": "16",
    "react-datepicker": "^1.6.0",
    "react-dom": "16",
    "react-router": "4.2",
    "react-router-dom": "4.2",
    "react_ujs": "^2.4.4",
    "reactstrap": "^6.4.0",
    "webpack": "^3.0.0"
  },
  "devDependencies": {
    "webpack-dev-server": "2.11.2"
  }
}
```
## setup and configuration

1. javascript/packs

1.1. client_and_server.js

client_only.scss
```css
@import 'react-datepicker/dist/react-datepicker.css';
```


```javascript

React = require('react');                      // react-js library
History = require('history');                  // react-router history library
ReactRouter = require('react-router');         // react-router js library
ReactRouterDOM = require('react-router-dom');  // react-router DOM interface
ReactRailsUJS = require('react_ujs');          // interface to react-rails

DatePicker = require('react-datepicker');

moment = require('moment');
require('moment/locale/el');

global.DatePicker = DatePicker
global.moment = moment

DatePickerInput = require('./date_picker_input.js');
global.DatePickerInput = DatePickerInput
```


## initial javascript integration

1.2. date_picker_input.js

```javascript

import DatePicker from 'react-datepicker';

export default class DatePickerInput extends React.Component
{
    constructor (props) {
        super(props)

        this.state = {
            startDate: moment(this.props.selected).isValid() ? moment(this.props.selected) : null //this.props.selected)
        };
        this.handleChange = this.handleChange.bind(this);
        this.handleBlur = this.handleBlur.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
    }

    handleChange(date) {
        this.setState({
            startDate: date
        });
        if(this.props.onChange) {
            this.props.onChange(this,date.format('YYYY-MM-DD'));
        }
    }
    handleBlur() {

        if(this.props.onBlur && this.state.startDate != null) {
            this.props.onBlur(this,this.state.startDate.format('YYYY-MM-DD'));
        }
    }
handleKeyDown(key) {
        if(this.props.onKeyDown && this.state.startDate != null) {
            this.props.onKeyDown(this,key.keyCode,this.state.startDate.format('YYYY-MM-DD'));
        }
    }


    render() {
        return <DatePicker
            selected={this.state.startDate}
            onChange={this.handleChange}
            onBlur={this.handleBlur}
            onKeyDown={this.handleKeyDown}
            placeholderText={"HH/MM/EEEE"}
            isClearable={true}
            dateFormat={['L','D/M/YY']}
        />;
    }
}
```
1.2.3 Import in hyperloop: app/hyperloop/components/date_picker_input.js

## hyperstack usage

```ruby
 DatePickerInput(selected: get_filter_value(filter, position)).
        on(:change) do |e,v|
          set_filter_value(v, filter, position)
        end.on(:blur) do |e,v|
          set_filter_value(v, filter, position)
        end.
            on(:key_down) {|e,k,v|
              if k == 13
                set_filter_value(v, filter, position)
                apply_filter_values
              end
            }
```
            
## final hyperstack component (get rid of that javascript...)

```javascript

React = require('react');                      // react-js library
History = require('history');                  // react-router history library
ReactRouter = require('react-router');         // react-router js library
ReactRouterDOM = require('react-router-dom');  // react-router DOM interface
ReactRailsUJS = require('react_ujs');          // interface to react-rails

DatePicker = require('react-datepicker').default;

moment = require('moment');
require('moment/locale/el');

global.DatePicker = DatePicker
global.moment = moment

//DatePickerInput = require('./date_picker_input.js');
//global.DatePickerInput = DatePickerInput
```



```ruby
class DatePickerInput < Hyperloop::Component
  param :selected, allow_nil: true
  param :onChange, type: Proc, default: nil, allow_nil: true
  param :onBlur, type: Proc, default: nil, allow_nil: true
  param :onKeyDown, type: Proc, default: nil, allow_nil: true

  before_mount do
    mutate.date params.selected
  end
  render(DIV) do
    parameter_hash = {placeholderText: "HH/MM/EEEE",
                      isClearable: true,
                      dateFormat: ['L', 'D/M/YY'],
                      todayButton: "Today",
                      onChange: lambda do |date|
                        return unless is_valid?
                        mutate.date date
                        params.onChange self, event_date
                      end,
                      onBlur: lambda {params.onBlur self, event_date},
                      onKeyDown: lambda {|key| params.onKeyDown self, key_code_for(key), event_date}
    }.merge(set_selected)
    DatePicker(parameter_hash)
  end

  def set_selected
    `#{state.date}==null || #{state.date} =='' `  ? {} : {selected: `moment(#{state.date})`}
  end

  def event_date
    `#{state.date}.format('YYYY-MM-DD')`
  end

  def key_code_for(key)
    `#{key}.keyCode`
  end

  def is_valid?(date)
    `moment(#{date}).isValid()`
  end
end
```

## final usage
```ruby
        DatePickerInput(
            selected: get_filter_value(filter, position),
            onChange: lambda {|e| set_filter_value(e.event_date, filter, position)}
        ).
            # on(:change) {|e,v| set_filter_value(v, filter, position)}.
            on(:blur) {|e, v| set_filter_value(v, filter, position)}.
            on(:key_down) do |e, k, v|
              if k == 13
                set_filter_value(v, filter, position)
                apply_filter_values
              end
            end
```

BTW, the .on(:change) (as you say) always passes an event first. To b e honest, I more than often like the lambda version above as you get only what the component is passing to you

## conclusion

