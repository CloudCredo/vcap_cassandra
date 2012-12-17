require 'socket'

class FreePortLocator

  def initialize(host, port_range)
    @port_range = port_range
    @host = host
  end

  def find_free_port
    port =  @port_range.find { |port|
      begin
        p = TCPSocket.new(@host, port)
        p.close
      rescue Errno::ECONNREFUSED
        port
      rescue => e
        next
      end
    }

    raise "All of the ports in the provided range #{@port_range.inspect} are taken.
    Please reconfigure your service.yml port range or free up the expected ports" unless port
    port
  end
end
