require 'spec_helper'

describe ActiveModel::Errors, js: true do
  # Start of ported Rails tests
  it 'delete' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors[:foo] << 'omg'
      errors.delete('foo')
      errors[:foo]
    end.to be_empty
  end

  it 'include?' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors[:foo] << 'omg'
      errors.include?(:foo) && errors.include?('foo')
    end.to be true
  end

  xit 'dup' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors[:foo] << 'bar'
      errors_dup = errors.dup
      errors_dup[:bar] << 'omg'
      errors_dup.messages.equal? errors.messages
    end.to be false
  end

  it 'has_key?' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors[:foo] << 'omg'
      errors.has_key?(:foo) && errors.has_key?('foo')
    end.to be true
  end

  it 'has_no_key' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors.has_key?(:name)
    end.to be false
  end

  it 'key?' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors[:foo] << 'omg'
      errors.key?(:foo) && errors.key?('foo')
    end.to be true
  end

  it 'no_key' do
    expect_evaluate_ruby do
      errors = ActiveModel::Errors.new(self)
      errors.key?(:name)
    end.to be false
  end

  context "with Person" do
    before do
      evaluate_ruby do
        class Person
          # extend ActiveModel::Naming # NOTE
          def initialize
            @errors = ActiveModel::Errors.new(self)
          end

          attr_accessor :name, :age
          attr_reader   :errors

          def validate!
            errors.add(:name, :blank, message: "cannot be nil") if name == nil
          end

          # def read_attribute_for_validation(attr)
          #   send(attr)
          # end

          class << self
            def human_attribute_name(attr, options = {})
              attr
            end
          end

          # def self.lookup_ancestors
          #   [self]
          # end
        end
      end
    end

    it 'clear errors' do
      expect_evaluate_ruby do
        person = Person.new
        person.validate!
        original_count = person.errors.count
        person.errors.clear
        original_count == 1 && person.errors.empty?
      end.to be true
    end

    it 'error access is indifferent' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(self)
        errors[:foo] << 'omg'

        errors['foo']
      end.to eq ['omg']
    end

    it 'values returns an array of messages' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(self)
        errors.messages[:foo] = 'omg'
        errors.messages[:baz] = 'zomg'

        errors.values
      end.to eq ['omg', 'zomg']
    end

    it 'values returns an empty array after try to get a message only' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(self)
        errors.messages[:foo]
        errors.messages[:baz]

        errors.values
      end.to eq []
    end

    it 'keys returns the error keys' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(self)
        errors.messages[:foo] << 'omg'
        errors.messages[:baz] << 'zomg'

        errors.keys
      end.to eq ['foo', 'baz']
    end

    it 'keys returns an empty array after try to get a message only' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(self)
        errors.messages[:foo]
        errors.messages[:baz]

        errors.keys
      end.to eq []
    end

    it 'detecting whether there are errors with empty?, blank?, include?' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors[:foo]
        person.errors.empty? && person.errors.blank? &&
          !person.errors.include?('foo')
      end.to be true
    end

    it 'include? does not add a key to messages hash' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.include?(:foo)

        person.errors.messages.key?(:foo)
      end.to be false
    end

    it 'adding errors using conditionals with Person#validate!' do
      expect_evaluate_ruby do
        person = Person.new
        person.validate!
        person.errors.full_messages
      end.to eq ['name cannot be nil']

      expect_evaluate_ruby do
        person = Person.new
        person.validate!
        person.errors[:name]
      end.to eq ['cannot be nil']
    end

    it 'add an error message on a specific attribute' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors[:name]
      end.to eq ['cannot be blank']
    end

    it 'add an error message on a specific attribute with a defined type' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :blank, message: 'cannot be blank')
        person.errors[:name]
      end.to eq ['cannot be blank']
    end

    it 'add an error with a symbol' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :blank)
        message = person.errors.generate_message(:name, :blank)
        person.errors[:name] == [message]
      end.to be true
    end

    it 'add an error with a proc' do
      expect_evaluate_ruby do
        person = Person.new
        message = Proc.new { 'cannot be blank' }
        person.errors.add(:name, message)
        person.errors[:name]
      end.to eq ['cannot be blank']
    end

    it 'added? detects indifferent if a specific error was added to the object' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.added?(:name, 'cannot be blank') &&
          person.errors.added?('name', 'cannot be blank')
      end.to be true
    end

    it 'added? handles symbol message' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :blank)
        person.errors.added?(:name, :blank)
      end.to be true
    end

    it 'added? handles proc messages' do
      expect_evaluate_ruby do
        person = Person.new
        message = Proc.new { 'cannot be blank' }
        person.errors.add(:name, message)
        person.errors.added?(:name, message)
      end.to be true
    end

    it 'added? defaults message to :invalid' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name)
        person.errors.added?(:name)
      end.to be true
    end

    it 'added? matches the given message when several errors are present for the same attribute' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.add(:name, 'is invalid')
        person.errors.added?(:name, 'cannot be blank')
      end.to be true
    end

    it 'added? returns false when no errors are present' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.added?(:name)
      end.to be false
    end

    it 'added? returns false when checking a nonexisting error and other errors are present for the given attribute' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'is invalid')
        person.errors.added?(:name, 'cannot be blank')
      end.to be false
    end

    it 'added? returns false when checking for an error, but not providing message arguments' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.added?(:name)
      end.to be false
    end

    xit 'added? returns false when checking for an error by symbol and a different error with same message is present' do
      I18n.backend.store_translations('en', errors: { attributes: { name: { wrong: 'is wrong', used: 'is wrong' } } })
      person = Person.new
      person.errors.add(:name, :wrong)
      assert !person.errors.added?(:name, :used)
    end

    it 'size calculates the number of error messages' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.size
      end.to eq 1
    end

    it 'count calculates the number of error messages' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.count
      end.to eq 1
    end

    it 'to_a returns the list of errors with complete messages containing the attribute names' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.add(:name, 'cannot be nil')
        person.errors.to_a
      end.to eq ['name cannot be blank', 'name cannot be nil']
    end

    it 'to_hash returns the error messages hash' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.to_hash
      end.to eq({ 'name' => ['cannot be blank'] })
    end

    it 'to_hash returns a hash without default proc' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.to_hash.default_proc
      end.to be_nil
    end

    it 'as_json returns a hash without default proc' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.as_json.default_proc
      end.to be_nil
    end

    it 'full_messages creates a list of error messages with the attribute name included' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.add(:name, 'cannot be nil')
        person.errors.full_messages
      end.to eq ['name cannot be blank', 'name cannot be nil']
    end

    it 'full_messages_for contains all the error messages for the given attribute indifferent' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.add(:name, 'cannot be nil')
        person.errors.full_messages_for(:name)
      end.to eq ['name cannot be blank', 'name cannot be nil']
    end

    it 'full_messages_for does not contain error messages from other attributes' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.add(:email, 'cannot be blank')
        person.errors.full_messages_for(:name)
      end.to eq ['name cannot be blank']
    end

    it 'full_messages_for returns an empty list in case there are no errors for the given attribute' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, 'cannot be blank')
        person.errors.full_messages_for(:email)
      end.to eq []
    end

    it 'full_message returns the given message when attribute is :base' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.full_message(:base, 'press the button')
      end.to eq 'press the button'
    end

    it 'full_message returns the given message with the attribute name included' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.full_message(:name_test, 'cannot be blank')
      end.to eq 'name_test cannot be blank'
    end

    it 'as_json creates a json formatted representation of the errors hash' do
      expect_evaluate_ruby do
        person = Person.new
        person.validate!
        person.errors.as_json
      end.to eq('name' => ['cannot be nil'])
    end

    it 'as_json with :full_messages option creates a json formatted representation of the errors containing complete messages' do
      expect_evaluate_ruby do
        person = Person.new
        person.validate!
        person.errors.as_json(full_messages: true)
      end.to eq('name' => ['name cannot be nil'])
    end

    xit 'generate_message works without i18n_scope' do
      person = Person.new
      assert_not_respond_to Person, :i18n_scope
      assert_nothing_raised {
        person.errors.generate_message(:name, :blank)
      }
    end

    it 'details returns added error detail' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :invalid)
        person.errors.details
      end.to eq('name' => [{ 'error' => 'invalid' }])
    end

    it 'details returns added error detail with custom option' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :greater_than, count: 5)
        person.errors.details
      end.to eq('name' => [{ 'error' => 'greater_than', 'count' => 5 }])
    end

    it 'details do not include message option' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :invalid, message: 'is bad')
        person.errors.details
      end.to eq('name' => [{ 'error' => 'invalid' }])
    end

    xit 'dup duplicates details' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(Person.new)
        errors.add(:name, :invalid)
        errors_dup = errors.dup
        errors_dup.add(:name, :taken)
        errors_dup.details == errors.details
      end.to be false
    end

    it 'delete removes details on given attribute' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(Person.new)
        errors.add(:name, :invalid)
        errors.delete(:name)
        errors.details[:name]
      end.to be_empty
    end

    it 'delete returns the deleted messages' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(Person.new)
        errors.add(:name, :invalid)
        errors.delete(:name)
      end.to eq ['invalid']
      # FIXME: Without the i18n features this test had to be changed
      # end.to eq ['is invalid']
    end

    it 'clear removes details' do
      expect_evaluate_ruby do
        person = Person.new
        person.errors.add(:name, :invalid)
        # assert_equal 1, person.errors.details.count
        person.errors.clear
        person.errors.details
      end.to be_empty
    end

    it 'merge errors' do
      expect_evaluate_ruby do
        errors = ActiveModel::Errors.new(Person.new)
        errors.add(:name, :invalid)

        person = Person.new
        person.errors.add(:name, :blank)
        person.errors.merge!(errors)

        # FIXME: Without the i18n features this test had to be changed
        # person.errors.messages == { name: ["can't be blank", 'is invalid'] } &&
        person.errors.messages == { name: ['blank', 'invalid'] } &&
          person.errors.details == { name: [{ error: :blank }, { error: :invalid }] }
      end.to be true
    end
  end
end
