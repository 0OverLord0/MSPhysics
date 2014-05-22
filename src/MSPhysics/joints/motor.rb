module MSPhysics
  class Motor < Joint

    # @param [Array<Numeric>, Geom::Point3d] pos Attach point in global space.
    # @param [Array<Numeric>, Geom::Vector3d] pin_dir Pivot direction in global
    #   space.
    # @param [Body, NilClass] parent Pass +nil+ to create joint without a parent
    #   body.
    # @param [Body, NilClass] child Pass +nil+ to create an initially
    #   disconnected joint.
    # @param [Numeric] rate Angular rate in degrees per second.
    # @param [Numeric] max_accel Maximum motor acceleration in degrees per
    #   second per second.
    # @param [Numeric] power Rotational force power in Watts (Joules / second).
    #   This value may also act as friction if the controller is set to zero.
    def initialize(pos, pin_dir, parent, child, rate = 1000, max_accel = 10, power = 50000)
      super(pos, pin_dir, parent, child, 6)
      @angular_rate = rate.degrees.abs
      @max_accel = max_accel.degrees.abs
      @power = power.abs
      @controller = 0
      @angle = 0
      @omega = 0
    end

    private

    def calc_angle(new_cos_angle, new_sin_angle)
      sin_angle = Math.sin(@angle)
      cos_angle = Math.cos(@angle)
      sin_da = new_sin_angle * cos_angle - new_cos_angle * sin_angle
      cos_da = new_cos_angle * cos_angle + new_sin_angle * sin_angle
      @angle += Math.atan2(sin_da, cos_da) - Math::PI/2
    end

    def submit_constraints(timestep)
      # Calculate the position of the pivot point and the Jacobian direction
      # vectors in global space.
      matrix0 = @child.get_matrix(0)*@local_matrix0
      matrix1 = @parent ? @parent.get_matrix(0)*@local_matrix1 : @local_matrix1
      pos0 = matrix0.origin.to_a.pack('F*')
      pos1 = matrix1.origin.to_a.pack('F*')
      # Restrict the movement on the pivot point along all three orthonormal
      # directions.
      Newton.userJointAddLinearRow(@joint_ptr, pos0, pos1, matrix1.xaxis.to_a.pack('F*'))
      Newton.userJointAddLinearRow(@joint_ptr, pos0, pos1, matrix1.yaxis.to_a.pack('F*'))
      Newton.userJointAddLinearRow(@joint_ptr, pos0, pos1, matrix1.zaxis.to_a.pack('F*'))
      # Get a point along the pin axis at some reasonable large distance from
      # the pivot.
      v1 = MSPhysics.scale_vector(matrix0.zaxis, PIN_LENGTH)
      q0 = (matrix0.origin + v1).to_a.pack('F*')
      v2 = MSPhysics.scale_vector(matrix1.zaxis, PIN_LENGTH)
      q1 = (matrix1.origin + v2).to_a.pack('F*')
      # Add two constraints row perpendicular to the pin vector.
      Newton.userJointAddLinearRow(@joint_ptr, q0, q1, matrix1.xaxis.to_a.pack('F*'))
      Newton.userJointAddLinearRow(@joint_ptr, q0, q1, matrix1.yaxis.to_a.pack('F*'))
      # Determine joint angle.
      sin_angle = (matrix0.yaxis * matrix1.yaxis) % matrix1.zaxis
      cos_angle = matrix0.yaxis % matrix1.yaxis
      calc_angle(sin_angle, cos_angle)
      # Determine joint omega.
      omega0 = @child.get_omega
      omega1 = @parent ? @parent.get_omega : Geom::Vector3d.new(0,0,0)
      @omega = (omega0 - omega1) % matrix1.zaxis
      Newton.userJointAddAngularRow(@joint_ptr, 0, matrix1.zaxis.to_a.pack('F*'))
      # Apply force
      return if @power == 0
      if @controller != 0
        accel = (@angular_rate*@controller - @omega).to_f
        accel = @max_accel*MSPhysics.sign(accel) if accel.abs > @max_accel
        Newton.userJointSetRowAcceleration(@joint_ptr, accel / timestep)
        Newton.userJointSetRowMinimumFriction(@joint_ptr, -@power)
        Newton.userJointSetRowMaximumFriction(@joint_ptr, @power)
	  else
	    Newton.userJointSetRowMinimumFriction(@joint_ptr, 0)
        Newton.userJointSetRowMaximumFriction(@joint_ptr, 0)
      end
	  Newton.userJointSetRowStiffness(@joint_ptr, 1.0)
    end

    def on_disconnect
      @angle = 0
      @omega = 0
    end

    public

    # Get joint rotated angle in degrees.
    # @return [Numeric]
    def angle
      @angle.radians
    end

    # Get joint omega in degrees per second.
    # @return [Numeric]
    def omega
      @omega.radians
    end

    # Get angular rate in degrees per second.
    # @return [Numeric]
    def angular_rate
      @angular_rate.radians
    end

    # Set angular rate in degrees per second.
    # @param [Numeric] rate
    def angular_rate=(rate)
      @angular_rate = rate.degrees.abs
    end

    # Get the maximum power applied to the rotation of the joint in Joules.
    # @return [Numeric]
    def power
      @power
    end

    # Set the maximum power applied to the rotation of the joint in Joules.
    # @param [Numeric] power
    def power=(power)
      @power = power.abs
    end

    # Get the maximum acceleration applied to the rotation of the joint in
    # degrees per second per second.
    # @return [Numeric]
    def max_accel
      @max_accel.radians
    end

    # Set the maximum acceleration applied to the rotation of the joint in
    # degrees per second per second.
    # @param [Numeric] accel
    def max_accel=(accel)
      @max_accel = accel.degrees.abs
    end

    # Get rotation direction and magnitude.
    # @return [Numeric]
    def controller
      @controller
    end

    # Set rotation direction and magnitude.
    # @note
    #   Change value signs to control rotation direction.
    #   Change value magnitude to control angular rate.
    #   That is angular rate is multiplied by the value magnitude.
    #   Set value zero to have motor rotate freely.
    # @param [Numeric, NilClass] value
    def controller=(value)
      @controller = value ? value.to_f : nil
    end

  end # class Motor
end # module MSPhysics
