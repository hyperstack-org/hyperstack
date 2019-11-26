# Javascript Components

Hyperstack gives you full access to the entire universe of JavaScript libraries and components directly within your Ruby code.

Everything you can do in JavaScript is simple to do in Ruby; this includes passing parameters between Ruby and JavaScript and even passing Ruby methods as JavaScript callbacks. See the JavaScript section for more information.

While it is quite possible to develop large applications purely in Hyperstack Components with a ruby back end like rails, you may eventually find you want to use some pre-existing React Javascript library. Or you may be working with an existing React-JS application, and want to just start adding some Hyperstack Components.

Either way you are going to need to import Javascript components into the Hyperstack namespace. Hyperstack provides both manual and automatic mechanisms to do this depending on the level of control you need.

## Importing React Components

Let's say you have an existing React Component written in Javascript that you would like to access from Hyperstack.

Here is a simple hello world component:

```javascript
window.SayHello = React.createClass({
  displayName: "SayHello",
  render: function render() {
    return React.createElement("div", null, "Hello ", this.props.name);
  }
})
```

Assuming that this component is loaded some place in your assets, you can then access this from Hyperstack by creating a wrapper Component:

```ruby
class SayHello < HyperComponent
  imports 'SayHello'
end

class MyBigApp < HyperComponent
  render(DIV) do
    # SayHello will now act like any other Hyperstack component
    SayHello name: 'Matz'
  end
end
```

The `imports` directive takes a string \(or a symbol\) and will simply evaluate it and check to make sure that the value looks like a React component, and then set the underlying native component to point to the imported component.

## Importing Javascript or React Libraries

Importing and using React libraries from inside Hyperstack is very simple and very powerful. Any JavaScript or React based library can be accessible in your Ruby code.

Using Webpacker \(or Webpack\) there are just a few simple steps:

* Add the library source to your project using `yarn` or `npm`
* Import the JavaScript objects you require
* Package your bundle with `webpack`
* Use the JavaScript or React component as if it were a Ruby class

Here is an example of setting up [Material UI](https://material-ui.com/):

Firstly, you install the library:

```text
// with yarn
yarn add @material-ui/core

// or with npm
npm install @material-ui/core
```

Next you import the objects you plan to us \(or you can import the whole library\)

```ruby
# app/javascript/packs/hyperstack.js

# to import the whole library
import * as Mui from '@material-ui/core';
global.Mui = Mui;

# or if you just want one component from the library
import Button from '@material-ui/core/Button';
global.Button = Button;
```

The run webpack to build your bundle:

```text
bin/webpack
```

Now you can use Material UI Components in your Ruby code:

```ruby
# if you imported the whole library
Mui.Button(variant: :contained, color: :primary) { "Click me" }.on(:click) do
  alert 'you clicked the button!'
end

# if you just imported the Button component
Button(variant: :contained, color: :primary) { "Click me" }.on(:click) do
  alert 'you clicked the button!'
end
```

Libraries used often with Hyperstack projects:

* [Material UI](https://material-ui.com/) Google's Material UI as React components
* [Semantic UI](https://react.semantic-ui.com/) A React wrapper for the Semantic UI stylesheet
* [ReactStrap](https://reactstrap.github.io/) Bootstrap 4 React wrapper

### Importing Image Assets via Webpack

If you store your images in app/javascript/images directory and want to display them in components, please add the following code to app/javascript/packs/application.js

```javascript
var webpackImagesMap = {};
var imagesContext = require.context('../images/', true, /\.(gif|jpg|png|svg)$/i);

function importAll (r) {
  r.keys().forEach(key => webpackImagesMap[key] = r(key));
}

importAll(imagesContext);

global.webpackImagesMap = webpackImagesMap;
```

The above code creates an images map and stores it in webpackImagesMap variable. It looks something like this

```javascript
{
     "./logo.png": "/packs/images/logo-3e11ad2e3d31a175aec7bb2f20a7e742.png",
     ...
}
```

Add the following helper

```ruby
# app/hyperstack/helpers/images_import.rb

module ImagesImport
  def img_src(filepath)
    img_map = Native(`webpackImagesMap`)
    img_map["./#{filepath}"]
  end
end
```

Include it into HyperComponent

```ruby
require 'helpers/images_import'
class HyperComponent
  ...
  include ImagesImport
end
```

After that you will be able to display the images in your components like this

```ruby
IMG(src: img_src('logo.png'))               # app/javascript/images/logo.png
IMG(src: img_src('landing/some_image.png')) # app/javascript/images/landing/some_image.png
```

## The dom\_node method

Returns the HTML dom\_node that this component instance is mounted to. Typically used in the `after_mount` method to setup linkages to external libraries.

Example:

TODO - write example

## The `as_node` and `to_n` methods

Sometimes you need to create a Component without rendering it so you can pass it as a parameter of a method. This model is used often in the React world.

The example below is taken from Semantic UI, building a [Tab Component](https://react.semantic-ui.com/modules/tab/#types-basic) with multiple tabs:

Here is the Javascript example:

```javascript
import React from 'react'
import { Tab } from 'semantic-ui-react'

const panes = [
  { menuItem: 'Tab 1', render: () => <Tab.Pane>Tab 1 Content</Tab.Pane> },
  { menuItem: 'Tab 2', render: () => <Tab.Pane>Tab 2 Content</Tab.Pane> },
]

const TabExampleBasic = () => <Tab panes={panes} />

export default TabExampleBasic
```

And here is the same example converted to Ruby:

```ruby
# notice we use .as_node to create the Component without rendering it
tab_1 = Sem.TabPane do
  P { 'Tab 1 Content' }
end.as_node

tab_2 = Sem.TabPane do
  P { 'Tab 2 Content' }
end.as_node

# notice how we use .to_n to convert the Ruby component to a native JS object
panes = [ {menuItem: 'Tab 1', render: -> { tab_1.to_n } },
          {menuItem: 'Tab 2', render: -> { tab_2.to_n } }
]

Sem.Tab(panes: panes.to_n )
```

## Including React Source

If you are in the business of importing components with a tool like Webpack, then you will need to let Webpack \(or whatever dependency manager you are using\) take care of including the React source code. Just make sure that you are _not_ including it on the ruby side of things. Hyperstack is currently tested with React versions 13, 14, and 15, so its not sensitive to the version you use.

However it gets a little tricky if you are using the react-rails gem. Each version of this gem depends on a specific version of React, and so you will need to manually declare this dependency in your Javascript dependency manager. Consult this [table](https://github.com/reactjs/react-rails/blob/master/VERSIONS.md) to determine which version of React you need. For example assuming you are using `npm` to install modules and you are using version 1.7.2 of react-rails you would say something like this:

```bash
npm install react@15.0.2 react-dom@15.0.2 --save
```

## Single Page Application CRUD example

Rails famously used scaffolding for Model CRUD \(Create, Read, Update and Delete\). There is no scaffolding in Hyperstack today, so here is an example which demonstrates how those simple Rails pages would work in Hyperstack.

This example uses components from the [Material UI](https://material-ui.com/) framework, but the principals would be similar for any framework \(or just HTML elements\).

In this example, we will have a table of users and the ability to add new users or edit a user from the list. As the user edits the values in the UserDialog, they will appear in the underlying table. You can avoid this behaviour if you choose by copying the values in the `before_mount` of the UserDialog, so you are not interacting with the model directly. Firstly the table of users:

```ruby
class UserIndex < HyperComponent
  render(DIV, class: 'mo-page') do
    UserDialog(user: User.new) # this will render as a button to add users
    Table do
      TableHead do
        TableRow do
          TableCell { 'Name' }
          TableCell { 'Gender' }
          TableCell { 'Edit' }
        end
      end
      TableBody do
        user_rows
      end
    end
  end

  def user_rows
    User.each do |user| # note User is a Hyperstack model (see later in the Isomorphic section)
      TableRow do
        TableCell { "#{user.first_name} #{user.last_name}" }
        TableCell { user.is_female ? 'Female' : 'Male' }
        # note the use of key so React knows which Component this refers to
        # this is very important for performance and to ensure the component is used
        TableCell { UserDialog(user: user, key: user.id) } # this will render as an edit button
      end
    end
  end
end
```

Then we need the actual Dialog \(Modal\) component:

```ruby
class UserDialog < HyperComponent
  param :user

  before_mount do
    @open = false
  end

  render do
    if @open
      render_dialog
    else
      edit_or_new_button.on(:click) { mutate @open = true }
    end
  end

  def render_dialog
    Dialog(open: @open, fullWidth: false) do
      DialogTitle do
        'User'
      end
      DialogContent do
        content
        error_messages if user.errors.any?
      end
      DialogActions do
        actions
      end
    end
  end

  def edit_or_new_button
    if user.new?
      Fab(size: :small, color: :primary) { Icon { 'add' } }
    else
      Fab(size: :small, color: :secondary) { Icon { 'settings' } }
    end
  end

  def content
    FormGroup(row: true) do
      # note .to_s to specifically cast to a String
      TextField(label: 'First Name', value: user.first_name.to_s).on(:change) do |e|
        user.first_name = e.target.value
      end
      TextField(label: 'Last Name', value: user.last_name.to_s).on(:change) do |e|
        user.last_name = e.target.value
      end
    end

    BR()

    FormLabel(component: 'legend') { 'Gender' }
    RadioGroup(row: true) do
      FormControlLabel(label: 'Male',
                       control: Radio(value: false, checked: !is_checked(user.is_female)).as_node.to_n)
      FormControlLabel(label: 'Female',
                       control: Radio(value: true, checked: is_checked(user.is_female)).as_node.to_n)
    end.on(:change) do |e|
      user.is_female = e.target.value
    end
  end

  def is_checked value
    # we need a true or false and not an object
    value ? true : false
  end

  def actions
    Button { 'Cancel' }.on(:click) { cancel }

    if user.changed? && validate_content
      Button(color: :primary, variant: :contained, disabled: (user.saving? ? true : false)) do
        'Save'
      end.on(:click) { save }
    end
  end

  def save
    user.save(validate: true).then do |result|
      mutate @open = false if result[:success]
    end
  end

  def cancel
    user.revert
    mutate @open = false
  end

  def error_messages
    user.errors.full_messages.each do |message|
      Typography(variant: :h6, color: :secondary) { message }
    end
  end

  def validate_content
    return false if user.first_name.to_s.empty?
    return false if user.last_name.to_s.empty?
    return false if user.is_female.nil?

    true
  end
end
```

