# frozen_string_literal: true

module Torque
  module PostgreSQL
    module Reflection
      module AssociationReflection

        def initialize(name, scope, options, active_record)
          super

          raise ArgumentError, <<-MSG.squish if options[:array] && options[:polymorphic]
            Associations can't be connected through an array at the same time they are
            polymorphic. Please choose one of the options.
          MSG
        end

        private

          # Check if the foreign key should be pluralized
          def derive_foreign_key(infer_from_inverse_of: true)
            # In rails 7.1 the kwarg was added infer_from_inverse_of. See the super implementation:
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/reflection.rb:761
            # Caller:
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/reflection.rb:507:in `foreign_key'"
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/associations/builder/belongs_to.rb:79:in `add_touch_callbacks'",
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/associations/builder/belongs_to.rb:23:in `define_callbacks'",
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/associations/builder/association.rb:34:in `build'",
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activerecord-7.1.1/lib/active_record/associations.rb:1887:in `belongs_to'",
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activestorage-7.1.1/app/models/active_storage/attachment.rb:27:in `<class:Attachment>'",
            # /.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/activestorage-7.1.1/app/models/active_storage/attachment.rb:20:in `<main>'",

            # Error in rails 7.1.1
            # Since the new arg is the hash {:infer_from_inverse_of=>true}, the call to super crashes
            result = super
            result = ActiveSupport::Inflector.pluralize(result) \
              if collection? && connected_through_array?
            result
          end

          # returns either +nil+ or the inverse association name that it finds.
          def automatic_inverse_of
            return super unless connected_through_array?

            if can_find_inverse_of_automatically?(self)
              inverse_name = options[:as] || active_record.name.demodulize
              inverse_name = ActiveSupport::Inflector.underscore(inverse_name)
              inverse_name = ActiveSupport::Inflector.pluralize(inverse_name)
              inverse_name = inverse_name.to_sym

              begin
                reflection = klass._reflect_on_association(inverse_name)
              rescue NameError
                # Give up: we couldn't compute the klass type so we won't be able
                # to find any associations either.
                reflection = false
              end

              return inverse_name if valid_inverse_reflection?(reflection)
            end
          end

      end

      ::ActiveRecord::Reflection::AssociationReflection.prepend(AssociationReflection)
    end
  end
end
