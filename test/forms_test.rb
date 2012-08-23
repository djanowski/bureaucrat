require_relative 'test_helper'

module FormTests
  class Test_inherited_form_with_a_CharField < BureaucratTestCase
    class OneForm < Forms::Form
      include Bureaucrat::Fields

      field :name, CharField.new
    end

    def test_have_a_BoundField
      form = OneForm.new
      assert_kind_of(Forms::BoundField, form[:name])
    end

    def test_be_bound_when_data_is_provided
      form = OneForm.new(name: 'name')
      assert_equal(true, form.bound?)
    end

    class Test_when_calling_valid < BureaucratTestCase
      def test_return_false_when_data_isnt_valid
        form = OneForm.new(name: nil)
        assert_equal(false, form.valid?)
      end

      def test_return_true_when_data_is_valid
        form = OneForm.new(name: 'valid')
        assert_equal(true, form.valid?)
      end
    end

    class Test_when_calling_errors < BureaucratTestCase
      def test_have_errors_when_invalid
        form = OneForm.new(name: nil)
        assert_operator(form.errors.size, :>, 0)
      end

      def test_not_have_errors_when_valid
        form = OneForm.new(name: 'valid')
        assert_equal(form.errors.size, 0)
      end
    end

    class Test_when_calling_changed_data < BureaucratTestCase
      def test_return_an_empty_list_if_no_field_was_changed
        form = OneForm.new
        assert_equal([], form.changed_data)
      end

      def test_return_a_list_of_changed_fields_when_modified
        form = OneForm.new(name: 'changed')
        assert_equal([:name], form.changed_data)
      end
    end
  end

  class Test_form_with_custom_clean_proc_on_field < BureaucratTestCase
    class CustomCleanForm < Forms::Form
      include Bureaucrat::Fields

      field :name, CharField.new

      def clean_name
        value = cleaned_data[:name]
        unless value == 'valid_name'
          raise Bureaucrat::ValidationError.new("Invalid name")
        end
        value.upcase
      end
    end

    def test_not_be_valid_if_clean_method_fails
      form = CustomCleanForm.new(name: 'other')
      assert_equal(false, form.valid?)
    end

    def test_be_valid_if_clean_method_passes
      form = CustomCleanForm.new(name: 'valid_name')
      assert_equal(true, form.valid?)
    end

    def test_set_the_value_to_the_one_returned_by_the_custom_clean_method
      form = CustomCleanForm.new(name: 'valid_name')
      form.valid?
      assert_equal('VALID_NAME', form.cleaned_data[:name])
    end

  end

  class Test_populating_objects < BureaucratTestCase
    class PopulatorForm < Forms::Form
      include Bureaucrat::Fields

      field :name, CharField.new(required: false)
      field :color, CharField.new(required: false)
      field :number, IntegerField.new(required: false)
    end

    def test_correctly_populate_an_object_with_all_fields
      obj = Struct.new(:name, :color, :number).new
      name_value = 'The Name'
      color_value = 'Black'
      number_value = 10

      form = PopulatorForm.new(name: name_value,
                               color: color_value,
                               number: number_value.to_s)

      assert form.valid?

      form.populate_object(obj)

      assert_equal(name_value, obj.name)
      assert_equal(color_value, obj.color)
      assert_equal(number_value, obj.number)
    end

    def test_correctly_populate_an_object_without_all_fields
      obj = Struct.new(:name, :number).new
      name_value = 'The Name'
      color_value = 'Black'
      number_value = 10

      form = PopulatorForm.new(name: name_value,
                               color: color_value,
                               number: number_value.to_s)

      assert form.valid?

      form.populate_object(obj)

      assert_equal(name_value, obj.name)
      assert_equal(number_value, obj.number)
    end

    def test_correctly_populate_an_object_with_all_fields_with_some_missing_values
      obj = Struct.new(:name, :color, :number).new('a', 'b', 2)

      form = PopulatorForm.new({})

      assert form.valid?

      form.populate_object(obj)

      assert_equal('', obj.name)
      assert_equal('', obj.color)
      assert_equal(nil, obj.number)
    end
  end

  class Test_nesting_forms < BureaucratTestCase
    class AttrsForm < Forms::Form
      include Bureaucrat::Fields

      field :color, CharField.new(required: true)
      field :number, CharField.new(required: true)
    end

    class NestedForm < Forms::Form
      include Bureaucrat::Fields

      field :name, CharField.new(required: false)
      field :attrs, FormField.new(AttrsForm)
    end

    def test_correctly_populate_an_object_with_all_fields
      obj = Struct.new(:name, :attrs).new

      name = "The Name"
      attrs = {"color" => "Black", "number" => "10"}

      form = NestedForm.new(name: name, attrs: attrs)

      assert form.valid?

      form.populate_object(obj)

      assert_equal(name, obj.name)
      assert_equal(attrs, obj.attrs)
    end

    def test_correctly_populate_an_object_without_all_fields
      obj = Struct.new(:name).new
      name = 'The Name'

      form = NestedForm.new(name: name,
                            attrs: {"color" => "blue"})

      assert form.valid?

      form.populate_object(obj)

      assert_equal(name, obj.name)
    end

    def test_correctly_populate_an_object_with_all_fields_with_some_missing_values
      obj = Struct.new(:name, :attrs).new('a', {"color" => 'b', "number" => 2})

      form = NestedForm.new({})

      assert form.valid?

      form.populate_object(obj)

      assert_equal('', obj.name)
      assert_equal(nil, obj.attrs)
    end
  end
end
