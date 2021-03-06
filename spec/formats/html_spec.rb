require File.dirname(__FILE__) + '/../spec_helper'

describe "HTML" do
  examples_from_yaml do |doc|
    RedClothParslet.new(doc['in']).to_html(:sort_attributes)
  end
  
  it "should not raise an error when orphaned parentheses in a link are followed by punctuation and words in HTML" do
    lambda {
      RedClothParslet.new(%Q{Test "(read this":http://test.host), ok}).to_html(:sort_attributes)
    }.should_not raise_error
  end
end
