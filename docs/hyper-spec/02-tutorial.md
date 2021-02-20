# Tutorial

For this quick tutorial lets assume you have an existing Rails app that
already uses RSpec to which you have added a first Hyperstack component to
try things out.

For your trial, you have created a very simple component that shows
the number of orders shipped by your companies website:

```ruby
class OrdersShipped < HyperComponent
  def format_number(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  render(DIV, class: 'orders-shipped') do
    format_number Order.shipped.count
  end
end
```

> Note that styling can be taken care of in the usual way by
> providing styles for the `orders-shipped` css class.  All we care
> about here is the *function* of the component.

Meanwhile `Order` is an ActiveRecord Model that would look something like this:

```ruby
class Order < ApplicationRecord
  ...
  scope :shipped, -> () { where(status: :shipped) }
  ...
end
```

> Note that when using ActiveRecord models in your specs you will
> need to add the appropriate database setup and cleaner methods like you would
> for any specs used with ActiveRecord.  We assume here that as each
> spec starts there are no records in the database

The `OrdersShipped` component can be mounted on any page of your site,
and assuming the proper policy permissions are provided it will
show the total orders shipped, and will dynamically increase in
realtime.

A partial spec for this component might look like this:

```ruby
require 'spec_helper'

describe 'OrdersShipped', :js do
  it 'dynamically displays the orders shipped' do
    mount 'OrdersShipped'
    expect(find('div.orders-shipped')).to have_content(0)
    Order.create(status: :shipped)
    expect(find('div.orders-shipped')).to have_content(1)
    Order.last.destroy
    expect(find('div.orders-shipped')).to have_content(0)
  end

  it '#format method' do
    on_client { @comp = OrdersShipped.new }
    ['1,234,567', '123', '1,234'].each do |n|
      expect { @comp.format_number(n.gsub(',','').to_i) }
        .on_client_to eq(n)
    end
  end
end
```

If you are familiar with Capybara then the first spec should
look similar to an integration spec.  The difference is instead
of visiting a page, we `mount` the `OrdersShipped` component on a blank page
that hyper-spec will set up for us.  This let's us unit test
components outside of any application specific view logic.

> Note that like Capybara we indicate that a client environment should
> be set up by adding the :js tag.

Once mounted we can use Capybara finders and matchers, to check
if our content is as expected.  Because we are running on the server
we can easily add and delete orders, and check the response on the UI.

The second spec shows how we can do some white box unit testing of our
component.  Instead of mounting the component we just create a new
instance which will be invisible since it was not mounted.  For this we
use the `on_client` method.

The `on_client` method takes a block, and will
compile that block using
Opal, and execute it on the client.  In this case we simply create a
new `OrderShipped` instance, and assign it to an instance variable, which as you
will see will continue to be available to us later in the spec.

> Note, if you are an RSpec purist, you would probably prefer to see
> something like `let` be used here instead of an instance variable. Shall we
> say its on the todo list.

Now that we have our test component setup we can test it's `format_number`
method.  To do this we put the test expression in a block followed by
`on_client_to`.  Again the block will be compiled using Opal, executed on
the client, and the result will be returned to the expectation.

Notice that the server side variable `n` can be read (but not written) within
the client block.  All local variables, memoized variables, and instance variables can
can be read in the client block as long as they represent objects that can be
sensibly marshalled and unmarshalled.

This has covered the basics of Hyperspec - in summary:

+ The `js` tag  indicates the spec will be using a client environment.
+ `mount`: Mount a component on a blank page.  This replaces the `visit` method
for unit testing components.
+ `on_client`:  Execute Ruby code on the client (and return the result).
+ `on_client_to`: Execute the expectation block on the client, and then check
the expectation (on the server.)
+ Instance variables retain their values between client execution blocks.
+ All variables accessible to the spec are copied to the client if possible.

There are many other features such as dealing with promises, passing data to
and from a mounted component, using the `Timecop` gem, and working with a `pry`
session.  So read on.
