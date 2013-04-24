require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ArgsHandler" do
  it "should be able to execute various forms of Web.input methods." do
    html = ArgsHandler.inputs([{
      :title => "Test 1",
      :name => :textest1,
      :type => :text,
      :default => "hmm",
      :value => "trala"
    },{
      :title => "Test 2",
      :name => :chetest2,
      :type => :checkbox,
      :default => true
    },{
      :title => "Test 4",
      :name => :textest4,
      :type => :textarea,
      :height => 300,
      :default => "Hmm",
      :value => "Trala"
    },{
      :title => "Test 5",
      :name => :filetest5,
      :type => :file
    },{
      :title => "Test 6",
      :type => :info,
      :value => "Argh"
    }])
    
    html.include?("<div><label>Test 1</label></div>").should eql(true)
  end
end
