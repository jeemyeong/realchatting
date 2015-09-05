require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "should get channels" do
    get :channels
    assert_response :success
  end

end
