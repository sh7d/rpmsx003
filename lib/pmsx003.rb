require 'serialport'
require 'rbuspirate'
require 'timeout'

require 'pmsx003/version'
require 'pmsx003/structs'
require 'pmsx003/checksum'
require 'pmsx003/commands'

module Pmsx003
  class Sensor
    include ChecksumHelpers
    attr_reader :last_read, :last_data, :mode, :sleep_s

    def initialize(device, mode: :active)
      @device = case device
                when SerialPort
                  device
                when String
                  if device.match?(/bp\:/)
                    initialize_buspirate(device)
                  else
                    SerialPort.new(device, 9_600, 8, 1, SerialPort::NONE)
                  end
                when Rbuspirate::Client
                  initialize_buspirate(device)
                else
                  raise ArgumentError, 'Shitty device arg'
                end

      @sleep_s = false
      switch_mode(mode)
    end

    def fetch
      case @mode
      when :active
        @last_data
      when :passive
        raise 'Device is in sleep mode' if @sleep_s

        retry_times = 2
        begin
          Timeout.timeout(5) do
            send_command(comm: :read_passive)
            handle_response
          end
        rescue Timeout::Error
          retry_times -= 1
          discard_device_buffer
          retry if retry_times.positive?
          raise 'Device communication error, timeout?'
        rescue BinData::ValidityError
          retry_times -= 1
          discard_device_buffer
          retry if retry_times.positive?
          raise 'Device communication error, shitty checksum'
        end
      end
    end

    def listen(interval = false)
      ![FalseClass, Integer, Float].include?(interval.class) &&
        raise(ArgumentError, 'Shitty argument')

      interval && @mode == :active &&
        raise('Cannot set interval if mode is active')

      raise 'Block must be given' unless block_given?

      if @mode == :active
        loop { yield @gath_queue.pop }
      else
        loop do
          yield fetch
          sleep interval
        end
      end
    end

    def switch_mode(mode)
      case mode
      when :active
        if @mode != :active
          send_command(comm: :change_mode, mode: true)
          init_gathering_thread if @mode != :active
        end
      when :passive
        if @mode != :passive
          @gath&.exit
          remove_instance_variable(:@gath_queue)
          send_command(comm: :change_mode, mode: false)
          sleep 0.4
          discard_device_buffer
        end
      else
        raise ArgumentError, 'Unknown mode'
      end
      @mode = mode
      true
    end

    def switch_sleep(switch)
      send_command(comm: :change_sleep, mode: !!switch)
      @sleep_s = !!switch
    end

    private

    def initialize_buspirate(device)
      if device.instance_of?(String)
        device = device.sub(/^bp\:/, '')
        device = SerialPort.new(device, 115_200, 8, 1, SerialPort::NONE)
      end

      device = Rbuspirate::Client.new(device) if device.instance_of?(SerialPort)
      device.enter_uart if device.mode != :uart
      device.interface.speed = 9_600
      device.interface.config_uart(pin_out_33: true, stop_bits: 1)
      device.interface.configure_peripherals(power: true)
      device.interface.enter_bridge
      device.interface.port
    end

    def init_gathering_thread
      @gath_queue = SizedQueue.new(1)
      @gath = Thread.new do
        loop do
          if @sleep
            handle_response
          else
            Timeout.timeout(10) { handle_response }
          end
          @gath_queue.pop if @gath_queue.size == @gath_queue.max
          @gath_queue << @last_data
        rescue BinData::ValidityError
          next
        rescue Timeout::Error
          raise 'Device communication error'
        end
      end
    end

    def send_command(comm:, mode: false)
      @comm = case comm
              when :read_passive
                Structs::Command.new(command: Commands::READ_PASSIVE, mode: 0)
              when :change_mode
                Structs::Command.new(command: Commands::Change::MODE, mode: mode)
              when :change_sleep
                Structs::Command.new(command: Commands::Change::SLEEP, mode: !mode)
              end
      @device.write(@comm.to_binary_s)
    end

    def handle_response
      @last_data = Structs::Response.read(@device).sensor_readings
      @last_read = Time.now
      @last_data
    end

    def discard_device_buffer
      @device.read(1) while @device.ready?
    end
  end
end
