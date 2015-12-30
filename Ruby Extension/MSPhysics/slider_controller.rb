module MSPhysics

  # @!visibility private
  @@instances ||= {}

  # Usually, a slider controller is created through the
  # <tt>MSPhysics::Common.#slider</tt> command. One may also access slider
  # instance and tick slider value or get slider information.
  # @example Retrieving slider controller instance by name.
  #   slider = MSPhysics::SliderController.get_by_name("my_slider")
  # @since 1.0.0
  class SliderController

    class << self

      # Verify that slider is valid.
      # @api private
      # @param [SliderController] slider
      # @return [void]
      # @raise [TypeError] if the slider is invalid or destroyed.
      def validate(slider)
        AMS.validate_type(slider, MSPhysics::SliderController)
        unless slider.is_valid?
          raise(TypeError, "SliderController #{slider} is invalid/destroyed!", caller)
        end
      end

      # Get range slider by name.
      # @param [String] name Slider name.
      # @return [SliderController, nil] A slider object or nil if no slider with
      #   given name exists.
      def get_by_name(name)
        @@instances[name]
      end

      # Destroy all sliders.
      # @return [Fixnum] Number of sliders destroyed.
      def destroy_all
        size = @@instances.size
        @@instances.each { |name, inst|
          inst.destroy
        }
        @@instances.clear
        size
      end

    end # class << self

    # Create a new slider controller.
    # @param [String] name Slider name.
    # @param [Numeric] default_value Starting value.
    # @param [Numeric] min Minimum value.
    # @param [Numeric] max Maximum value.
    # @param [Numeric] step Snap step.
    def initialize(name, default_value = 0, min = 0, max = 1, step = 0)
      @name = name.to_s
      if @sliders[@name]
        raise(TypeError, "Slider with given name already exists", caller)
      end
      @min = min.to_f
      @max = AMS.clamp(max.to_f, @min, nil)
      @step = AMS.clamp(step.to_f, 0, nil)
      default_value = AMS.clamp(default_value.to_f, @min, @max)
      @valid = true
      @instances[@name] = self
    end

    # Get slider name.
    def get_name
      SliderController.validate(self)
      @name
    end

    # Get slider minimum value.
    # @return [Numeric]
    def get_min
      SliderController.validate(self)
      @min
    end

    # Set slider minimum value.
    # @param [Numeric] value
    # @return [Numeric] The new value.
    def set_min(value)
      SliderController.validate(self)
      @min = AMS.clamp(value.to_f, nil, @max)
    end

    # Get slider maximum value.
    # @return [Numeric]
    def get_max
      SliderController.validate(self)
      @max
    end

    # Set slider maximum value.
    # @param [Numeric] value
    # @return [Numeric] The new value.
    def set_max(value)
      SliderController.validate(self)
      @max = AMS.clamp(value.to_f, @min, nil)
    end

    # Get slider snap step.
    # @return [Numeric]
    def get_step
      SliderController.validate(self)
      @step
    end

    # Set slider snap step.
    # @param [Numeric] value
    # @return [Numeric] The new value.
    def set_step(value)
      SliderController.validate(self)
      @step = AMS.clamp(value.to_f, 0, nil)
    end

    # Get slider value.
    # @return [Numeric]
    def get_value
      SliderController.validate(self)
    end

    # Set slider value.
    # @param [Numeric] value
    # @return [Numeric] The new value.
    def set_value(value)
      SliderController.validate(self)
    end

    # Destroy slider.
    # @note Calling any methods after a slider is destroyed, except for the
    #   {#is_valid?} method, will result in a TypeError.
    # @return [void]
    def destroy
      SliderController.validate(self)
      @valid = false
    end

    # Determine if slider is not destroyed.
    # @return [Boolean]
    def is_valid?
      @valid
    end

  end # class SliderController
end # module MSPhysics