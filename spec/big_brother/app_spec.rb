require 'spec_helper'

module BigBrother
  describe App do
    def app
      App
    end

    describe "/" do
      it "works" do
        get "/"
        last_response.status.should == 200
        last_response.body.should == "HELLO"
      end
    end

    describe "PUT /cluster/:name" do
      it "marks the cluster as monitored" do
        BigBrother.clusters['test'] = Factory.cluster(:name => 'test')

        put "/cluster/test"

        last_response.status.should == 200
        last_response.body.should == ""
        BigBrother.clusters['test'].should be_monitored
      end

      it "returns 'not found' if the cluster does not exist" do
        put "/cluster/test"

        last_response.status.should == 404
        last_response.body.should == "Cluster test not found"
      end

      it "populates IPVS" do
        first = Factory.node(:address => '127.0.0.1')
        second = Factory.node(:address => '127.0.0.2')
        BigBrother.clusters['test'] = Factory.cluster(:name => 'test', :fwmark => 100, :scheduler => 'wrr', :nodes => [first, second])

        put "/cluster/test"

        last_response.status.should == 200
        last_response.body.should == ""
        BigBrother.clusters['test'].should be_monitored
        @recording_executor.commands.first.should == "ipvsadm --add-service --fwmark-service 100 --scheduler wrr"
        @recording_executor.commands.should include("ipvsadm --add-server --fwmark-service 100 --real-server 127.0.0.1 --ipip --weight 100")
        @recording_executor.commands.should include("ipvsadm --add-server --fwmark-service 100 --real-server 127.0.0.2 --ipip --weight 100")
      end
    end

    describe "DELETE /cluster/:name" do
      it "marks the cluster as no longer monitored" do
        BigBrother.clusters['test'] = Factory.cluster(:name => 'test')
        BigBrother.clusters['test'].start_monitoring!

        delete "/cluster/test"

        last_response.status.should == 200
        last_response.body.should == ""
        BigBrother.clusters['test'].should_not be_monitored
      end

      it "returns 'not found' if the cluster does not exist" do
        delete "/cluster/test"

        last_response.status.should == 404
        last_response.body.should == "Cluster test not found"
      end
    end
  end
end
