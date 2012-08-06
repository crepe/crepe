module Crepe
  module Util
    # Forwards all future includes to objects that have already been
    # extended by (or have included) the parent module.
    #
    # Default Ruby behavior:
    #
    #   # A module is defined...
    #   module A
    #   end
    #
    #   # ...and included in a class.
    #   class B
    #     include Module A
    #   end
    #
    #   # Given another module...
    #   module C
    #     def c
    #     end
    #   end
    #
    #   # ...included in the first...
    #   module A
    #     include Module C
    #   end
    #
    #   # ...the class will not have access to its methods.
    #   B.new.c # NoMethodError: undefined method `c' for #<B>
    #
    # To prevent the above error, the original module could have
    # included ChainedInclude:
    #
    #   module A
    #     extend ChainedInclude
    #   end
    module ChainedInclude

      private

        def include mod
          super
          extended_by.each { |object| object.extend mod }
          included_by.each { |base| base.__send__ :include, mod }
        end

        def extended object
          super
          extended_by << object
        end

        def included base
          super
          included_by << base
        end

        def extended_by
          @_extended_by ||= []
        end

        def included_by
          @_included_by ||= []
        end

    end
  end
end
