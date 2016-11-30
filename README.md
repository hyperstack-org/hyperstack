#  ![](https://github.com/Serzhenka/hyper-loop-logos/blob/master/hyper-router_150.png)Hyper-router

Reactrb Router allows you write and use the React Router in Ruby through Opal.

### Note

This gem is in the process of being re-written. It will be based on latest react-router which is way better. Please see the [v2-4-0 branch](https://github.com/reactrb/reactrb-router/tree/v2-4-0).

During the transition you will need to pick between the following branches:

1. **0-7-stable** is the source for the deprecated reactive-router gem, and is compatible with the deprecated reactive-ruby gem.  
2. **0-8-stable** is the current active source for reactrb-router, and is compatible with the reactrb gem, and is bundled with the pre 1.0 react-router js library source.
3. **v2-4-0** is being developed, and is compatible with the latest reactrb and react-router.  While not released, it is stable and is recommended if you are developing a new app and need a router.

## Installation (0.8 and beyond...)

Add this line to your application's Gemfile:

```ruby
gem 'reactrb-router'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reactrb-router

## Usage (0.8 only)

The router is a React component that loads other components depending on the current URL.

Unlike other components there can only be one router on a page.

To get you started here is a sample router.   

```ruby
module Components
  module Accounts

    class Show

      include React::Router  # instead of React::Component, you use React::Router

      # the routes macro creates the mapping between URLs and components to display

      routes(path: '/account/:user_id') do  # i.e. we expect to see something like /account/12345
        # routes can be nested  the dashboard will be at /account/12345/dashboard
        # the DashboardRoute component will be mounted
        route(name: 'Dashboard', path: 'dashboard', handler: Components::Accounts::DashboardRoute)
        route(path: 'orders', name: 'Orders', handler: Components::Accounts::OrdersRoute)
        # when displaying an order we need the order order as well as the user_id
        route(path: 'orders/:order_id', name: 'Order', handler: Components::Accounts::OrderRoute)
        route(path: 'statement', name: 'Statement', handler: Components::Accounts::StatementRoute)
        # the special redirect route
        redirect(from: '/account/:user_id', to: 'Dashboard')
      end

      # you grab the url params and preprocess them using the router_param macro.
      # when Router is mounted it will receive the :user_id from the url.  In this case we grab
      # the corresponding active_record model.

      router_param :user_id do |id|
        User.find(id)
      end

      # like any component routers can have params that are passed in when the router is mounted

      param :user_param, type: User
      param :user_orders_param, type: [Order]
      param :production_center_address_param, type: Address
      param :open_invoices_param
      param :user_profiles_param, type: [PaymentProfile]
      param :user_addresses_param, type: [Address]

      # because the underlying javascript router has no provisions to pass params we
      # will export states and copy the params to the states so the lower components can read them
      # expect this get fixed in the near future

      export_state :user
      export_state :production_center_address
      export_state :open_invoices
      export_state :payment_profiles
      export_state :addresses

      # the router also makes a good place for other top level states to be housed (i.e. the flux architecture)
      export_state :order_count

      before_mount do
        # before mounting the router we copy the incoming params that the lower level components will need
        user! user_param
        production_center_address! production_center_address_param
        open_invoices! open_invoices_param
        payment_profiles! user_profiles_param
        addresses! user_addresses_param

        order_count! user.orders.count  # grab our top level state info and save it away

      end

      # For routers you define a show method instead of a render method
      def show
        div do
          div.account_nav do

            # link is a special router component that generates an on page link, that will maintain history etc.
            # basically an intelligent anchor tag.  When a user clicks a link, it will rerender the router, update
            # the history etc.
            # So for example when 'My Statement' is clicked. The route changes to /account/:id/statement

            link(to: 'Dashboard', class: 'no-underline btn btn-default', params: { user_id: user.id }) { 'Account Dashboard' }
            link(to: 'Orders', class: 'no-underline btn btn-default', params: { user_id: user.id }) { 'My Quotes & Orders' }
            link(to: 'Statement', class: 'no-underline btn btn-default', params: { user_id: user.id }) { 'My Statement' }

          end
        # someplace in the router show method you will have route_handler component which mounts and renders the component
        # indicated by the current route.
        route_handler   
        end
      end
    end

    # We can't pass parameters to the routed components, so we set up these mini components
    # which grab the state from router and send it along to the actual component

    class DashboardRoute

      include React::Component

      def render
        AccountDashboard user: Show.user, addresses: Show.addresses, payment_profiles: Show.payment_profiles
      end

    end

    class StatementRoute

      include React::Component

      def render
        Statement production_center_address: Show.production_center_address,
        open_invoices: Show.open_invoices, current_invoices: Show.open_invoices[:invoices],
        mailing_address: Show.open_invoices[:mailing_address]
      end

    end

    class OrdersRoute

      include React::Component

      def render
        AccountOrders user: Show.user #, orders: Show.orders
      end

    end

    class OrderRoute

      include React::Component

      router_param :order_id do |id|
        Order.find(id)
      end

      def render
        OrderShow(order: order_id, referrer: 'account')
      end

    end

  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/reactrb/reactrb-router/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
