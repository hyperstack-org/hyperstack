require 'spec_helper'
require 'test_components'

describe "dictionary examples", js: true do


  Hyperstack.configuration do |config|
    config.transport = :action_cable
    config.channel_prefix = "synchromesh"
  end

  before(:all) do
    class DictionaryEntry < ActiveRecord::Base
      def self.build_tables
        connection.create_table(:dictionary_entries, force: true) do |t|
          t.string :word
          t.string :pronunciation
        end
      end
    end

    class Definition < ActiveRecord::Base
      def self.build_tables
        connection.create_table(:definitions, force: true) do |t|
          t.integer   :dictionary_entry_id
          t.text      :definition
          t.integer   :votes
        end
      end
    end

  end

  before(:each) do


    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:small, :portrait)

    isomorphic do
      class DictionaryEntry < ActiveRecord::Base
        has_many :definitions
        scope :defined, ->() {joins(:definitions).where('definitions.dictionary_entry_id IS NOT NULL')}
      end
      class Definition < ActiveRecord::Base
        belongs_to :dictionary_entry
        scope :order_by_votes, ->() { order('votes DESC') }
      end
    end

    DictionaryEntry.build_tables
    Definition.build_tables

    foo = DictionaryEntry.create(word: 'foo', pronunciation: 'foo')
    Definition.create(
      definition: 'every programmers favorite symbol',
      votes: 3, dictionary_entry: foo
    )

    DictionaryEntry.create(word: 'meaningless')

    bar = DictionaryEntry.create(word: 'bar', pronunciation: 'bahr')
    Definition.create(
      definition: 'every programmers 2nd favorite symbol',
      votes: 2, dictionary_entry: bar
    )
    Definition.create(
      definition: 'every programmers favorite place',
      votes: 4, dictionary_entry: bar
    )

    ruby = DictionaryEntry.create(word: 'ruby', pronunciation: 'roo-bee')
    Definition.create(
      definition: 'every programmers favorite language',
      votes: 30, dictionary_entry: ruby
    )
    Definition.create(
      definition: 'a red gem stone',
      votes: 4, dictionary_entry: ruby
    )

    hyperstack = DictionaryEntry.create(word: 'hyperstack', pronunciation: 'hahy-per-loop')
    Definition.create(
      definition: 'every programmers favorite UI framework',
      votes: 25, dictionary_entry: hyperstack
    )
    Definition.create(
      definition: 'high speed rail for the 21st century',
      votes: 24, dictionary_entry: hyperstack
    )

  end

  it "displays a word" do
    mount "WordOfTheDay" do

class WordOfTheDay < HyperComponent

  # The current word displayed is stored in the
  # entry state variable.   We use a state
  # variable so that the display will refresh
  # when the user chooses a new word

  define_state :entry

  def pick_entry!
    # pick a random word and assign the selected record to entry
    # the ! will notify react that the state is changing.
    state.entry! DictionaryEntry.all[rand(DictionaryEntry.count)]
  end

  # before we mount our component pick the first entry to display

  before_mount :pick_entry!

  render(DIV) do
    DIV { "Total definitions: #{DictionaryEntry.count}" }
    DIV do
      DIV { "word: #{state.entry.word}" }
      DIV { "pronunciation: #{state.entry.pronunciation}" }
      definitions
      AddDefinition(entry: state.entry)
    end
    BUTTON { 'pick another' }.on(:click) { pick_entry! }
  end

  def definitions
    # Display the ordered list of definitions
    # note the use of relationships as scopes
    # To keep things tidy we break out ShowDefinition
    # as a separate component.
    OL do
      state.entry.definitions.order_by_votes.each do |definition|
        LI { ShowDefinition definition: definition }
      end
    end
  end
end

class ShowDefinition < HyperComponent

  # The ShowDefinition component has one param
  # of type as "Definition". Typing  is not
  # necessary but will raise a warning if the
  # type is wrong, so its helpful in debug.

  param :definition, type: Definition

  # display the number of votes and let the user
  # up or down vote the definition

  render(DIV) do
    DIV do
      SPAN { "votes: #{params.definition.votes}" }
      BUTTON { '+' }.on(:click) { inc_vote(1) }
      BUTTON { '-' }.on(:click) { inc_vote(-1) }
    end
    DIV { params.definition.definition }
  end

  def inc_vote(amt)
    # update the votes attribute on the definition
    # record.  If votes goes to zero destroy the
    # record, otherwise just save it.
    params.definition.votes += amt
    if params.definition.votes.zero?
      params.definition.destroy
    else
      params.definition.save
    end
  end
end

class AddDefinition < HyperComponent

  # The AddDefinition component takes a
  # DictionaryEntry, and will allow the user
  # add a new definition.

  param :entry, type: DictionaryEntry

  # The definition state just holds the current
  # text that the user has typed.

  # More interesting is adding_definition which
  # controls whether we diplay a editable text area,
  # or the 'add new definition' button.

  define_state definition: ''
  define_state :adding_definition

  def text_area
    # display the text area and provide  add& cancel buttons
    DIV do
      TEXTAREA(rows: 4, cols: 30, value: state.definition)
      .on(:change) { |e| state.definition! e.target.value }

      BUTTON { 'add' }
      .on(:click) { add_definition }

      BUTTON { 'cancel' }.on(:click) { state.adding_definition! false }
    end
  end

  def add_definition
    # Use ActiveRecord create to add a new
    # record.  Using the promise returned by
    # create we will wait until the operation is
    # finished to update the UI.
    Definition.create(
      definition: state.definition,
      votes: 1, dictionary_entry: params.entry
    ).then do
      state.adding_definition! false
      state.definition! ''
    end
  end

  render do
    if state.adding_definition
      text_area
    else
      BUTTON { 'add new definition' }
      .on(:click) { state.adding_definition! true }
    end
  end
end
    end
    #binding.pry
  end

end
