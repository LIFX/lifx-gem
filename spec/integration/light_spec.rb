require 'spec_helper'

module LIFX
  describe Light do
    before(:all) do
      $lifx = LIFX::Client.new(logger: Yell.new(STDERR))
      $lifx.discover
      begin
        Timeout.timeout(5) do
          while $lifx.lights.empty?
            sleep 0.5
          end
        end
      rescue Timeout::Error
        raise "Could not find any lights"
      end
    end
    let(:light) { $lifx.lights.values.first }

    def wait_until(timeout = 1, &block)
      Timeout.timeout(timeout) do
        while !block.call
          sleep 0.1
        end
      end
    rescue Timeout::Error
      $stderr.puts("Timeout exceeded")
    end

    describe '#set_color' do
      it "sets the color of the light" do
        color = Color.hsb(rand(360), rand, rand)
        light.set_color(color, 0)
        sleep 0.26
        light.refresh
        $lifx.flush
        wait_until { light.color == color }
        light.color.should == color
      end
    end

    describe '#set_label' do
      it "sets the label of the light" do
        label = light.label.sub(/\d+|$/, rand(100).to_s)
        light.set_label(label)
        wait_until { light.label == label }
        light.label.should == label
      end
    end

  end
end
