class CacheWrapper
  LOG_HITS = false

  # Wraps any in-memory Cache class (typically a Singleton), providing cache operations
  # such as expiry and refresh.
  # Usage:
  # > IC['util.cache'].init(IC['kms.key_cache'], "signature key")
  #
  #
  class << self

    # Initialises the cache
    # @param cache [Class]        => Any class (although typically a class that includes Singleton) that provides
    #                                attr_accessors for the desired cache methods as well as <cache_method>_expiry accessors
    # @param caller_name [String] => A handle for the caller to be used for logging
    # @return [Util::Cache]   => A Singleton objec initialised with the cache.
    def init(cache, caller_name="")
      new(cache, caller_name)
    end

    def default_expired_fn
      -> cache, method { !cache.send("#{method}_expiry").nil? && cache.send("#{method}_expiry") < Time.now.utc }.curry
    end

  end # self

  def initialize(singleton, caller_name)
    @singleton = singleton
    @caller_name = caller_name
  end

  # Takes a cache method, and expiry predicate fn and a on_miss fn and returns the value of the cache_method
  # @param cache_method [Symbol] => An attr_accessor on the in-memory cache (singleton)
  # @param expired_fn [Lambda]   => The test for cache expiry, the default is defined here and is based on expiry time.
  #                                 Takes the underlying cache object and the cache_method as args
  # @param on_miss [Lambda]      => Should reading the cache_method return nil, this fn is called to re-initialise the cache,
  #                                 Takes 1 arg, the current value in the cache.
  def read(cache_method, expired_fn: self.class.default_expired_fn, on_miss: F.identity)
    if cache.send(cache_method) && !expired_fn.(cache, cache_method) #not_expired?(cache_method)
      log_cache_hit
      get(cache_method)
    else
      log_cache_failure
      write(cache_method, on_miss.(get(cache_method)))
    end
  end

  # Provides access to the underlying cache through its cache methods
  def get(cache_method)
    cache.send(cache_method)
  end

  # Puts a value into the cache
  def put(cache_method, value)
    cache.send("#{cache_method}=", value)
  end

  # Takes a cache_method and a property structure, and updates the cache.
  # @param cache_method [Symbol] => the property method to be updated
  # @param property [Hash]       => {value: Any, expires_in: ActiveSupport::Duration}
  def write(cache_method, property)
    raise NotImplementedError.new("Cache must implement #{cache_method}= and #{cache_method}_expiry=") unless cache.respond_to?("#{cache_method}=") && cache.respond_to?("#{cache_method}_expiry=")
    put("#{cache_method}_expiry", Time.now.utc + property[:expires_in]) if property.has_key?(:expires_in)
    put(cache_method, property[:value])
  end

  def clear(cache_method)
    put(cache_method, nil)
    put("#{cache_method}_expiry", nil)
  end

  private

  def log_cache_hit
    Rails.logger.info("#{@caller_name}; cache hit") unless LOG_HITS
  end

  def log_cache_failure
    Rails.logger.info("#{@caller_name}; cache miss")
  end

  def cache
    @singleton.instance
  end

end
