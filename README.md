# hyper-resource

[Github Repo](https://github.com/janbiedermann/hyper-resource "Github Repo")

HyperResource is an affective way of moving data between your server and clients when using Hyperstack and Rails.

[![Reactivity Demo](http://img.youtube.com/vi/fPSpESBbeMQ/0.jpg)](http://www.youtube.com/watch?v=fPSpESBbeMQ "Reactivity Demo")

[Documentation](https://janbiedermann.github.io/hyper-resource "Github Repo")

Supports Pusher and ActionCable (thanks @gabrielrios)

## Motivation

+ To co-exist with a resource based REST API
+ To have ActiveRecord type Models shared by both the client and server code
+ To be ORM/database agnostic (tested with ActiveRecord on Postgres and Neo4j.rb on Neo4j)
+ To fit the 'Rails way' as far as possible (under the covers, HyperResource is a traditional REST API)
+ To keep all Policy checking and authorisation logic in the Rails Controllers
+ To allow a stages implementation

## Staged implementation

HyperResource is designed to be implemented in stages and each stage delivers value in its own right, so the developer only needs to go as far as they like.

A record can be of any ORM but the ORM must implement:
```ruby
record_class.find(id) # to get a record
record.id # a identifier
record.updated_at # a time stamp
record.destroyed? # to identify if its scheduled for destruction

# when using relations controller
record.touch # to update updated_at, identicating that something about that record changed
             # for example it has been added to a relation
```

### Stage 1 - Wrap a REST API with Ruby classes to represent Models

The simplest implementation of HyperResource is a client side only wrapper of an existing REST API which treats each REST Resource as a Ruby class.

```ruby
# in your client-cide code
class Customer
  include ApplicationHyperRecord
end

# then work with the Customer class as if it were an ActiveRecord
customer = Customer.new(name: 'John Smith')
customer.save # ---> POST api/customer.json ... {name: 'John Smith' }
puts customer.id # 123

# to find a record
customer = Customer.find(123) # ---> GET api/customer/123.json
puts customer.name # `John Smith`
```

### Stage 2 - Adapt your Models so the client and server code share the same Models

HyperResource supports ActiveRecord associations and scopes so you can DRY up your code and the client an server can share the same Models.

```ruby
module ApplicationHyperRecord
  def self.included(base)
    if RUBY_ENGINE == 'opal'
      base.include(HyperRecord)
    else
      base.extend(HyperRecord::ServerClassMethods)
    end
  end
end

class Customer
  include ApplicationHyperRecord
  has_many :addresses

  unless RUBY_ENGINE == 'opal'
    # methods which should only exist on the server
  end
end

customer = Customer.find(123) # ---> GET api/customer/123.json
customer.addresses.each do |address|
  puts address.post_code
end
```

### Stage 3 - Implement a Redis based pub-sub mechanism so the client code is notified when the server data changes

```ruby
class ApplicationController
  include Hyperstack::Resource::PubSub

  def my_action
    # available methods for pubsub
    publish_collection(base_record, collection_name, record = nil)
    publish_record(record)
    publish_scope(record_class, scope_name)

    subscribe_collection(collection, base_record = nil, collection_name = nil)
    subscribe_record(record)
    subscribe_scope(collection, record_class = nil, scope_name = nil)

    pub_sub_collection(collection, base_record, collection_name, causing_record = nil)
    pub_sub_record(record)
    pub_sub_scope(collection, record_class, scope_name)
  end
end
```

EXAMPLE

## Implementation

## Implementation

Hyperstack needs to be installed and working before you install HyperResource. These instructions are likely to change/be simplified as this Gem matures.

+ Add the gems (make sure its the latest version)

`gem 'hyper-resource', '1.0.0.lap86'`
`gem 'opal-jquery', github: 'janbiedermann/opal-jquery', branch: 'why_to_n'`
`gem 'opal-activesupport', github: 'opal/opal-activesupport', branch: 'master'`

+ Require HyperResource in your `hyperstack_webpack_loader.rb` file

`require 'hyper-resource'`
`require 'opal-jquery'`

 + Update your `application_record.rb` file and move it to the `hyperstack/models` folder

 ```
# application_record.rb
if RUBY_ENGINE == 'opal'
  class ApplicationRecord
    def self.inherited(base)
      base.include(HyperRecord)
    end
  end
else
  class ApplicationRecord < ActiveRecord::Base
    # when updating this part, also update the ApplicationRecord in app/models/application_record.rb
    # for rails eager loading in production, so production doesn't fail
    self.abstract_class = true
    extend HyperRecord::ServerClassMethods
    include HyperRecord::PubSub
  end
end
 ```

+ Move the models you want on the client to the `hyperstack/models` folder

+ Make sure you guard anything in your model which you do not want on the client:

```
unless RUBY_ENGINE == 'opal'
  # herein stuff that you do not want on the client (Devise, etc)
end
```

+ Add Pusher to your gemfile

`gem pusher`

+ Add it with Yarn

`yarn add pusher-js`

+ Then import in your `app.js`

`import Pusher from 'pusher-js';`
`global.Pusher = Pusher;`

+ Add your api endpoint to your client code, for example in `hyperstack_webpack_loader.rb`

`HyperResource.api_path = '/api/endpoint'`

(You may set the api_path per model too)

TODO:
+ Use the supplied catch all controller or write your own

vs.

+ Create you API controllers as normal - ensure they return JSON in this format

```
{
  "members":[
    {"member":{"id":1,"email":"a@b.com","first_name":"John","last_name":"Smith"}},
    {"member":{"id":2,"email":"b@c.com","first_name":null,"last_name":null}}
  ]
}
```

Rabl gem example view:

```
collection @members, root: :members
attributes :id,
  :email,
  :first_name,
  :last_name
```

+ Create your API controller and make sure to implement `show` as this is called by HyperResource. Please see the example controller below for details on pub_sub

```ruby
module Api
  class PersonasController < ApplicationController
    # GET /api/personas.json
    def index
      authorize(Persona)

      @personas = Persona.all
      subscribe_scope(@personas, Persona, :all)
      respond_to do |format|
        format.json {}
      end
    end

    # GET /api/personas/123.json
    def show
      @persona = Persona.find(params[:id])

      authorize(@persona)

      subscribe_record(@persona)
      respond_to do |format|
        format.json {}
      end
    end

    # POST /api/plans/1/personas.json
    def create
      authorize(Persona)

      @persona = Persona.new(persona_params)

      subscribe_record(@persona)
      respond_to do |format|
        if @persona.save
          subscribe_record(@persona)
          publish_scope(Persona, :all)
          format.json { render :show, status: :created }
        else
          format.json { render json: @persona.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /api/personas/1.json
    def update
      @persona = Persona.find(params[:id])
      @persona.assign_attributes(persona_params)

      authorize(@persona)

      respond_to do |format|
        if @persona.update(persona_params)
          pub_sub_record(@persona)
          format.json { render :show, status: :ok }
        else
          format.json { render json: @persona.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /personas/1.json
    def destroy
      @persona = Persona.find(params[:id])
      # authorize @persona

      @persona.destroy
      publish_record(@persona)
      respond_to do |format|
        format.json { head :no_content }
      end
    end

    private

    def persona_params
      permitted_keys = Persona.attribute_names.map(&:to_sym)
      %i[id created_at updated_at].each do |key|
        permitted_keys.delete(key)
      end
      params.require(:data).permit(permitted_keys)
    end
  end
end
```

+ Install Redis and add the following to your `hyperstack.rb`

```ruby
config.redis_instance = if ENV['REDIS_URL']
                            Redis.new(url: ENV['REDIS_URL'])
                          else
                            Redis.new
                          end
```

+ Add the following to your `ApplicationController`

```
include Hyperstack::Resource::PubSub
```

+ Add these routes:

```
namespace :api, defaults: { format: :json } do

    # introspection
    # get '/:model_klass/relations', to: 'relations#index'
    # get '/:model_klass/methods', to: 'methods#index'
    # get '/:model_klass/methods/:id', to: 'methods#show'
    # patch '/:model_klass/methods/:id', to: 'methods#update'
    # get '/:model_klass/properties', to: 'properties#index'
    get '/:model_klass/scopes', to: 'scopes#index'
    get '/:model_klass/scopes/:id', to: 'scopes#show'
    patch '/:model_klass/scopes/:id', to: 'scopes#update'

```

+ Add the `ScopesController` as per the example in this Gem
