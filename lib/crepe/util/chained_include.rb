module Crepe
  module Util
    module ChainedInclude

      private

        def included child
          super
          included_by << child
        end

        def include mod
          super
          included_by.each { |child| child.__send__ :include, mod }
        end

        def included_by
          @_included_by ||= []
        end

    end
  end
end
