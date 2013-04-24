require 'rack/request'

module Crepe
  # A thin wrapper over {Rack::Request} that provides helper methods to
  # better access request attributes.
  class Request < Rack::Request

    # Responds to {#match} so that {Rack::Mount} can route versions.
    class Versions < Array
      def match condition
        grep(condition).first
      end
    end

    @@env_keys = Hash.new { |h, k| h[k] = "HTTP_#{k.upcase.tr '-', '_'}" }

    @config = API.config

    class << self
      attr_accessor :config
    end

    attr_writer :body

    def method
      @method ||= env['crepe.original_request_method'] || request_method
    end

    def head?
      method == 'HEAD'
    end

    def path
      @path ||= Util.normalize_path! super
    end

    def headers
      @headers ||= Hash.new { |h, k| h.fetch @@env_keys[k], nil }.update env
    end

    def params
      @params ||= (env['rack.routing_args'] || {}).merge super
    end

    def body
      @body ||= (b = super).respond_to?(:read) ? b.read.tap { b.rewind } : b
    end

    def credentials
      @credentials ||= begin
        request = Rack::Auth::Basic::Request.new env
        request.provided? ? request.credentials : []
      end
    end

    def query_version
      self.GET[self.class.config[:version][:name]].to_s
    end

    def header_versions
      Versions.new accepts.media_types.map(&:version).compact
    end

    def accepts
      @accepts ||= Accept.new(
        Util.media_type(params[:format]) || headers['Accept'] || '*/*'
      )
    end

  end
end
