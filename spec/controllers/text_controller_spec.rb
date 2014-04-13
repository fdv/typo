require 'spec_helper'

describe TextController do
  let!(:blog) { create(:blog) }

  describe :humans do
    before(:each) { get :humans, format: 'txt' }

    it { expect(response).to be_success }
    it { expect(response.body).to eq(blog.humans) }
  end
end
