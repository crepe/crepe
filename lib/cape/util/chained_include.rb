module Cape
  module Util
    module ChainedInclude

      private

        def include mod
          super
          extended_by.each { |child| child.extend mod }
          included_by.each { |child| child.__send__ :include, mod }
        end

        def extended child
          super
          extended_by << child
        end

        def included child
          super
          included_by << child
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
