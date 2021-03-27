# Javascript Components

Hyperstack gives you full access to the entire universe of JavaScript libraries and components directly within your Ruby code.

Everything you can do in JavaScript is simple to do in Opal-Ruby; this includes passing parameters between Ruby and JavaScript and even passing Ruby methods as JavaScript callbacks.

> **[For more information on writing Javascript within your Ruby code...](notes.md#javascript)**

## Importing Javascript or React Libraries

Importing and using React libraries from inside Hyperstack is very simple and very powerful. Any JavaScript or React based library can be accessible in your Ruby code.

Using Webpacker there are just a few simple steps:

* Add the library source to your project using `yarn` or `npm`
* Import the JavaScript objects you require
* Use the JavaScript or React component as if it were a Ruby class

Here is an example using the [Material UI](https://material-ui.com/) library:

Firstly, you install the library:

```text
yarn add @material-ui/core
```

Next you import the objects you plan to use:

```javascript
// app/javascript/packs/client_and_server.js

// to import the whole library
Mui = require('@material-ui/core')
// or to import a single component
Button = require('@material-ui/core/Button')
```

Theoretically webpacker will detect the change and rebuild everything, but you might have to do the following:

```
bin/webpack # rebuild the webpacks
rm -rf tmp/cache # clear the cached sprockets files
```

Now you can use Material UI Components in your Ruby code:

```ruby
# if you imported the whole library
Mui::Button(variant: :contained, color: :primary) { "Click me" }.on(:click) do
  alert 'you clicked the primary button!'
end

# if you just imported the Button component
Button(variant: :contained, color: :secondary) { "Click me" }.on(:click) do
  alert 'you clicked the secondary button!'
end
```

Libraries used often with Hyperstack projects:

* [Material UI](https://material-ui.com/) Google's Material UI as React components
* [Semantic UI](https://react.semantic-ui.com/) A React wrapper for the Semantic UI stylesheet
* [ReactStrap](https://reactstrap.github.io/) Bootstrap 4 React wrapper

### Making Custom Wrappers - WORK IN PROGRESS ...

<img align="left" width="100" height="100" style="margin-right: 20px" src="https://github.com/hyperstack-org/hyperstack/blob/edge/docs/wip.png?raw=true"> Hyperstack will automatically import Javascript components and component libraries as discussed above.  Sometimes for
complex libraries that you will use a lot it is useful to add some syntactic sugar to the wrapper.

This can be done using the `imports` directive and the `Hyperstack::Component::NativeLibrary` superclass.

### Importing Image Assets via Webpack

If you store your images in `app/javascript/images` directory and want to display them in components, please add the following code to `app/javascript/packs/application.js`

```javascript
webpackImagesMap = {};
var imagesContext = require.context('../images/', true, /\.(gif|jpg|png|svg)$/i);

function importAll (r) {
  r.keys().forEach(key => webpackImagesMap[key] = r(key));
}

importAll(imagesContext);
```

The above code creates an images map and stores it in webpackImagesMap variable. It looks something like this

```javascript
{
     "./logo.png": "/packs/images/logo-3e11ad2e3d31a175aec7bb2f20a7e742.png",
     ...
}
```

Add the following helpers to your HyperComponent class

```ruby
# app/hyperstack/helpers/images_import.rb

class HyperComponent
  def self.img_src(file_path)  # for use outside a component
    @img_map ||= Native(`webpackImagesMap`)
    @img_map["./#{file_path}"]
  end
  def img_src(file_path) # for use in a component
    HyperComponent.img_src(file_path)
  end
  ...
end
```

After that you will be able to display the images in your components like this

```ruby
IMG(src: img_src('logo.png'))               # app/javascript/images/logo.png
IMG(src: img_src('landing/some_image.png')) # app/javascript/images/landing/some_image.png
```

## jQuery

Hyperstack comes with a jQuery wrapper that you can optionally load.  First add jQuery using yarn:
```shell
yarn add jquery
```
then insure jQuery is required in your client_only.js packs file:
```javascript
// app/javascript/packs/client_only.js
jQuery = require('jquery');
```
finally require it in your hyper_component.rb file:
```ruby
# app/hyperstack/hyper_component.rb

require 'hyperstack/component/jquery'
```
You can access jQuery anywhere in your code using the `jQ` method.
For details see https://github.com/opal/opal-jquery

> Note most of the time you will not need to manipulate the dom directly.


## The dom\_node method

Returns the HTML dom\_node that this component instance is mounted to.  For example you can use `dom_node` to
set the focus on an input after its mounted.

```ruby
class FocusedInput < HyperComponent
  others :others
  after_mount do
    jQ[dom_node].focus
  end
  render do
    INPUT(others)
  end
end
```
