class AppnexusApi::Resource

  attr_reader :dbg_info, :raw_json

  def initialize(json, service, dbg_info = nil)
    @raw_json = json
    @service = service
    @dbg_info = dbg_info
  end

  def update(route_params={}, body_params={})
    resource = @service.update(id, route_params, body_params)
    @raw_json = resource.raw_json
    self
  end

  def delete(route_params={})
    @service.delete(id, route_params)
  end

  def method_missing(sym, *args, &block)
    if @raw_json.respond_to?(sym)
      @raw_json.send(sym, *args, &block)
    elsif @raw_json.has_key?(sym.to_s)
      return @raw_json[sym.to_s]
    else
      super(sym, *args, &block)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @raw_json.respond_to?(method_name) || @raw_json.has_key?(method_name.to_s) || super
  end

  def to_s
    @raw_json.inspect
  end
end
