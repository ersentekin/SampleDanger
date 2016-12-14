require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe Danger::DangerCodeStyleValidation do
    it 'should be a plugin' do
      expect(Danger::DangerCodeStyleValidation.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.code_style_validation
      end
    end
  end
end
