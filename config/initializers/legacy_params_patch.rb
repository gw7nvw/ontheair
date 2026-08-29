# config/initializers/legacy_params_patch.rb

ActiveSupport.on_load(:action_controller) do
  class ActionController::Parameters
    # Forward missing Hash methods directly to the underlying parameters hash
    def method_missing(method_name, *args, &block)
      if Hash.public_instance_methods(false).include?(method_name) || {}.respond_to?(method_name)
        # Rails 8 stores the raw data in @parameters
        @parameters.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      Hash.public_instance_methods(false).include?(method_name) || {}.respond_to?(method_name) || super
    end

    # Explicitly restore critical methods that might skip method_missing
    [:slice, :except, :keep_if, :reject!, :select!, :to_hash].each do |method_name|
      define_method(method_name) do |*args, &block|
        @parameters.send(method_name, *args, &block)
      end
    end
  end
end

