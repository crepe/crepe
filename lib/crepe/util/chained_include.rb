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
    # To prevent the above error, the original module could have been
    # extended with ChainedInclude:
    #
    #   module A
    #     extend ChainedInclude
    #   end
    #   class B
    #     include Module A
    #   end
    #   module C
    #     def c
    #     end
    #   end
    #   module A
    #     include Module C
    #   end
    #   B.new.c # => nil
    module ChainedInclude

      private

        def include mod
          super
          extending.each { |o| o.singleton_class.__send__ :include, mod }
          included_by.each { |base| base.__send__ :include, mod }
          prepending.each { |base| base.__send__ :include, mod }
        end

        def prepend mod
          super
          extending.each { |o| o.singleton_class.__send__ :prepend, mod }
          included_by.each { |base| base.__send__ :prepend, mod }
          prepending.each { |base| base.__send__ :prepend, mod }
        end

        def extended object
          super
          extending << object
        end

        def included base
          super
          included_by << base
        end

        def prepended base
          super
          prepending << base
        end

        def extending
          @_extending ||= []
        end

        def included_by
          @_included_by ||= []
        end

        def prepending
          @_prepending ||= []
        end

    end
  end
end
