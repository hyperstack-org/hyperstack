require 'spec_helper'
require 'reactrb_router/test_components'

describe 'Router class', js: true do
  it 'can have a #history hook' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        alias history browser_history

        def routes
          route('/react_test/:test_id', mounts: App)
        end
      end
    end

    page.should have_content('Rendering App: No Children')
  end

  it 'can have a #create_element hook' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        param :on_create_element, type: Proc

        def create_element(component, component_params)
          params.on_create_element(component.name)
          if component.name == 'App'
            React.create_element(component, component_params.merge(optional_param: 'I am the App'))
          elsif component.name == 'Child1'
            component_params[:optional_param] = 'I am a Child'
          elsif component.name == 'Child2'
            React.create_element(component,
                                 component_params.merge(optional_param: 'I am also a Child')).to_n
          end
        end

        def routes
          route('/', mounts: App) do
            route('/child1', mounts: Child1)
            route('/child2', mounts: Child2)
            route('/child3', mounts: Child3)
          end
        end
      end
    end

    page.should have_content('I am the App')
    page.evaluate_script('window.ReactRouter.hashHistory.push("child1")')
    page.should have_content('I am a Child')
    page.evaluate_script('window.ReactRouter.hashHistory.push("child2")')
    page.should have_content('I am also a Child')
    page.evaluate_script('window.ReactRouter.hashHistory.push("child3")')
    page.should have_content('Child3 got routed')
    event_history_for('create_element')
      .flatten.should eq(%w(App Child1 App Child2 App Child3 App))
  end

  it 'can have a #stringify_query hook' do
    mount 'TestRouter', foo: :bar do
      class TestRouter < React::Router
        param :on_stringify_query, type: Proc

        def stringify_query(query)
          params.on_stringify_query(query)
          query[:foo] = 14 if query[:foo]
          query.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join('&')
        end

        def routes
          route('/', mounts: App) do
            route('/link', mounts: LinkChild)
            route('/child1', mounts: Child1)
          end
        end
      end
    end
    page.evaluate_script('window.ReactRouter.hashHistory.push({pathname: "link"})')
    click_link 'child1'
    page.evaluate_script('window.location.href').scan('foo=14').should_not be_empty
    event_history_for('stringify_query').flatten.should eq([{ 'foo' => 12 }, { 'foo' => 14 }])
  end

  it 'can have a #parse_query_string hook' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        param :on_parse_query_string, type: Proc

        def parse_query_string(query_string)
          params.on_parse_query_string(query_string)
          hash = Hash.new(0)
          query_string.split('&').each do |param|
            hash[param.split('=')[0]] = param.split('=')[1]
          end
          hash[:foo] = 14 if hash[:foo]
          hash
        end

        def routes
          route('/', mounts: App) do
            route('/child1', mounts: Child1)
            route('/query', mounts: QueryChild)
          end
        end
      end
    end

    page.evaluate_script('window.ReactRouter.hashHistory.push("query?foo=12")')
    page.should have_content('query props = {"foo"=>14}')
    event_history_for('parse_query_string').flatten.should eq(['', 'foo=12'])
  end

  it 'can have a #on_error hook' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        param :on_error, type: Proc

        def on_error(message)
          params.on_error(message.to_s)
        end

        def routes
          route('/', mounts: App) do
            route('/test1', mounts: App) do |ct|
              puts 'building test1 routes now'
              TestRouter.promise = ct.promise.fail { |msg| "Rejected: #{msg}" }
            end
            route('/test2', mounts: lambda do |ct|
              puts 'building test2 route'
              TestRouter.promise = ct.promise.then { |id| Object.const_get id }
            end)
          end
        end
      end
    end

    page.evaluate_script('window.ReactRouter.hashHistory.push({pathname: "test2"})')
    run_on_client { TestRouter.promise.resolve('Child1') }
    page.should have_content('Child1 got routed')

    page.evaluate_script('window.ReactRouter.hashHistory.push({pathname: "/"})')
    page.evaluate_script('window.ReactRouter.hashHistory.push({pathname: "test1/boom"})')
    run_on_client { TestRouter.promise.reject('This is never going to work') }
    page.should have_content('Rendering App: No Children')

    page.evaluate_script('window.ReactRouter.hashHistory.push({pathname: "test2"})')
    run_on_client { TestRouter.promise.resolve('BOGUS') }
    page.should have_content('Rendering App: No Children')
    event_history_for('error').flatten.should eq(['Rejected: This is never going to work',
                                                  'uninitialized constant BOGUS'])
  end

  it 'can have a #on_update hook' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        param :on_update, type: Proc

        def on_update(_props, state)
          params.on_update(state[:location][:pathname])
        end

        def routes
          route('/', mounts: App) do
            route('/child1', mounts: Child1)
          end
        end
      end
    end

    page.evaluate_script('window.ReactRouter.hashHistory.push("child1")')
    event_history_for('update').flatten.should eq(['/child1'])
  end

  it 'can redefine the #render method' do
    mount 'TestRouter' do
      class TestRouter < React::Router
        param :on_render, type: Proc

        def render
          params.on_render('rendered')
          super
        end

        def routes
          route('/', mounts: App)
        end
      end
    end

    page.should have_content('Rendering App: No Children')
    event_history_for('render').flatten.should eq(['rendered'])
  end
end
