require 'spec_helper'

describe RewardStation::Client do

  let(:service) { RewardStation::Client.new :client_id => '100080', :client_password => 'fM6Rv4moz#', :token => "e285e1ed-2356-4676-a554-99d79e6284b0" }

  describe "required options" do
    it "should raise ArgumentError on missing client_id" do
      lambda{ RewardStation::Client.new :client_password => "" }.should raise_error(ArgumentError)
    end

    it "should raise ArgumentError on missing client_password" do
      lambda{ RewardStation::Client.new :client_id => "" }.should raise_error(ArgumentError)
    end

    it "should not rause ArgumentError if all required parameters present" do
      lambda{ RewardStation::Client.new :client_id => "", :client_password => "" }.should_not raise_error(ArgumentError)
    end
  end

  describe "new_token_callback" do
    it "should raise ArgumentError if options is not lambda or proc" do
      lambda{ RewardStation::Client.new :client_id => "", :client_password => "", :new_token_callback => "" }.should raise_error(ArgumentError)
    end

    it "should not raise ArgumentError if option is lambda or proc" do
      lambda{ RewardStation::Client.new :client_id => "", :client_password => "", :new_token_callback => Proc.new { } }.should_not raise_error(ArgumentError)
    end
  end

  describe 'stub' do
    it "should create stub" do
      RewardStation::Client.stub.should be_a(RewardStation::StubClient)
    end

    describe 'stub service' do
      let(:service) {RewardStation::Client.stub}

      it "should return token" do
        service.return_token.should eq("e285e1ed-2356-4676-a554-99d79e6284b0")
      end
    end
  end

  describe "return_token" do

    describe "on valid response" do
      before { savon.stub(:return_token).and_return(:return_token) }

      it "should return valid token" do
        service.return_token.should eq("e285e1ed-2356-4676-a554-99d79e6284b0")
      end

      it "should not raise InvalidAccount exception" do
        lambda{ service.return_token }.should_not raise_error(RewardStation::InvalidAccount)
      end
    end

    describe "on invalid account response" do
      before { savon.stub(:return_token).and_return(:return_token_invalid) }

      it "should raise InvalidAccount exception" do
        lambda{ service.return_token }.should raise_error(RewardStation::InvalidAccount)
      end
    end

    describe "on soap error" do
      before { savon.stub(:return_token).and_return.raises_soap_fault }

      it "should raise ConnectionError exception" do
        lambda{ service.return_token }.should raise_error(RewardStation::ConnectionError)
      end
    end

    describe "on http error" do
      before { savon.stub(:return_token).and_return(:code => 404).raises_http_error }

      it "should raise HttpError exception" do
        lambda{ service.return_token }.should raise_error(RewardStation::ConnectionError)
      end
    end
  end

  describe "award_points" do
    let(:service) {
      RewardStation::Client.new :client_id => '100080',
                                :client_password => 'fM6Rv4moz#',
                                :program_id => 90,
                                :point_reason_code_id => 129,
                                :token => "e285e1ed-2356-4676-a554-99d79e6284b0"
    }

    describe "on valid response" do
      before { savon.stub(:award_points).and_return(:award_points) }

      it "should return valid confirm code" do
        service.award_points(130, 10, "Action 'Some' taken").should eq("9376")
      end
    end

    describe "on invalid token response" do
      before { savon.stub(:award_points).and_return(:award_points_invalid_token) }

      it "should not raise InvalidToken exception" do
        lambda{ service.award_points(130, 10, "Action 'Some' taken") }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on soap error" do
      before { savon.stub(:award_points).and_return.raises_soap_fault }

      it "should raise ConnectionError exception" do
        lambda{ service.award_points(130, 10, "Action 'Some' taken") }.should raise_error(RewardStation::ConnectionError)
      end
    end

    describe "on http error" do
      before { savon.stub(:award_points).and_return(:code => 404).raises_http_error }

      it "should raise HttpError exception" do
        lambda{ service.award_points(130, 10, "Action 'Some' taken") }.should raise_error(RewardStation::ConnectionError)
      end
    end

  end

  describe "return_user" do

    describe "on valid response" do
      before { savon.stub(:return_user).and_return(:return_user) }

      it "should return valid user data" do
        service.return_user(130).should eq(:user_id => '6725',
                                           :client_id => '100080',
                                           :user_name => 'john3@company.com',
                                           :encrypted_password => nil,
                                           :first_name => 'John',
                                           :last_name => 'Smith',
                                           :address_one => nil,
                                           :address_two => nil,
                                           :city => nil,
                                           :state_code => nil,
                                           :province => nil,
                                           :postal_code => nil,
                                           :country_code => 'USA',
                                           :phone => nil,
                                           :email => 'john@company.com',
                                           :organization_id => '0',
                                           :organization_name => nil,
                                           :rep_type_id => '0',
                                           :client_region_id => '0',
                                           :is_active => true,
                                           :point_balance => '10',
                                           :manager_id => '0',
                                           :error_message => nil)
      end

      it "should not raise InvalidToken exception" do
        lambda{ service.return_user(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on invalid token response" do
      before { savon.stub(:return_user).and_return(:return_user_invalid_token) }

      it "should not raise InvalidToken exception" do
        lambda{ service.return_user(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on invalid user response" do
      before { savon.stub(:return_user).and_return(:return_user_invalid_user) }

      it "should raise InvalidUser exception" do
        lambda{ service.return_user(130) }.should raise_error(RewardStation::InvalidUser)
      end
    end

    describe "on soap error" do
      before { savon.stub(:return_user).and_return.raises_soap_fault }

      it "should raise ConnectionError exception" do
        lambda{ service.return_user(130) }.should raise_error(RewardStation::ConnectionError)
      end
    end

    describe "on http error" do
      before { savon.stub(:return_user).and_return(:code => 404).raises_http_error }

      it "should raise HttpError exception" do
        lambda{ service.return_user(130) }.should raise_error(RewardStation::ConnectionError)
      end
    end
  end

  describe "return_point_summary" do
    describe "on valid request" do
      before { savon.stub(:return_point_summary).and_return(:return_point_summary) }

      it "should return valid summary" do
        service.return_point_summary(130).should eq(:user_id => '577',
                                                    :is_active => true,
                                                    :points_earned => '465',
                                                    :points_redeemed => '0',
                                                    :points_credited => '0',
                                                    :points_balance => '465')
      end

      it "should not raise InvalidToken exception" do
        lambda{ service.return_point_summary(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on invalid token request" do
      before { savon.stub(:return_point_summary).and_return(:return_point_summary_invalid_token) }

      it "should not raise InvalidToken exception" do
        lambda{ service.return_point_summary(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on soap error" do
      before { savon.stub(:return_point_summary).and_return.raises_soap_fault }

      it "should raise ConnectionError exception" do
        lambda{ service.return_point_summary(130) }.should raise_error(RewardStation::ConnectionError)
      end
    end

    describe "on http error" do
      before { savon.stub(:return_point_summary).and_return(:code => 404).raises_http_error }

      it "should raise HttpError exception" do
        lambda{ service.return_point_summary(130) }.should raise_error(RewardStation::ConnectionError)
      end
    end
  end

  describe "create_user" do
    describe 'missing information' do

      before { savon.stub(:update_user).and_return(:create_user_missing_info) }

      it "should raise MissingInformation error" do
        lambda { service.create_user :organization_id => '150' }.should raise_error(RewardStation::MissingInformation)
      end
    end
  end

  describe "update_user" do
    let(:service) { RewardStation::Client.new :client_id => '100080', :client_password => 'fM6Rv4moz#', :organization_id => '150', :token => "e285e1ed-2356-4676-a554-99d79e6284b0" }

    describe "on create user valid request" do
      before { savon.stub(:update_user).and_return(:create_user) }

      it "should return valid response" do
        service.create_user(
            :email => 'john5@company.com',
            :first_name => 'John',
            :last_name => 'Smith',
            :user_name => 'john5@company.com',
            :balance => 0
        ).should eq(:user_id => '6727',
                    :client_id => '100080',
                    :user_name => 'john5@company.com',
                    :email => 'john5@company.com',
                    :encrypted_password => nil,
                    :first_name => 'John',
                    :last_name => 'Smith',
                    :address_one => nil,
                    :address_two => nil,
                    :city => nil,
                    :state_code => nil,
                    :province => nil,
                    :postal_code => nil,
                    :country_code => 'USA',
                    :phone => nil,
                    :organization_id => '150',
                    :organization_name => nil,
                    :rep_type_id => '0',
                    :client_region_id => '0',

                    :is_active => true,
                    :point_balance => '0',
                    :manager_id => '0',
                    :error_message => nil)
      end

      it "should not raise InvalidToken exception" do
        lambda{
          service.create_user(:email => 'john5@company.com',
                              :first_name => 'John',
                              :last_name => 'Smith',
                              :user_name => 'john5@company.com',
                              :balance => 0)
        }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on create user invalid request" do
      before { savon.stub(:update_user).and_return(:create_user_exists) }

      it "should raise UserAlreadyExists exception" do
        lambda{
          service.update_user(130, {
              :email => 'john5@company.com',
              :first_name => 'John',
              :last_name => 'Smith',
              :user_name => 'john5@company.com',
              :balance => 0
          })
        }.should raise_error(RewardStation::UserAlreadyExists)
      end
    end

  end

  describe "return_popular_products" do
    describe "on valid request" do
      before { savon.stub(:return_popular_products).and_return(:return_popular_products) }

      it "should return valid response" do
        products = service.return_popular_products(130)
        products.should be_a(Array)
        products.size.should eq(35)
        products.first.should eq(:product_id => 'MC770LLA',
                                 :name => 'iPad 2 with Wifi - 32GB',
                                 :description => 'The NEW Apple iPad 2 - Thinner, lighter, and full of great ideas.  Once you pick up iPad 2, it’ll be hard to put down.  That’s the idea behind the all-new design. It’s 33 percent thinner and up to 15 percent lighter, so it feels even more comfortable in your hands.  And, it makes surfing the web, checking email, watching movies, and reading books so natural, you might forget there’s incredible technology under your fingers.<br><br><b>Dual-core A5 chip</b>.<br> Two powerful cores in one A5 chip mean iPad can do twice the work at once.  You’ll notice the difference when you’re surfing the web, watching movies, making FaceTime video calls, gaming, and going from app to app to app.  Multitasking is smoother, apps load faster, and everything just works better.<br><br><b>Superfast graphics</b>. <br>With up to nine times the graphics performance, gameplay on iPad is even smoother and more realistic.  And faster graphics help apps perform better — especially those with video.  You’ll see it when you’re scrolling through your photo library, editing video with iMovie, and viewing animations in Keynote.<br><br><b>Battery life keeps on going. So you can, too.</b><br> Even with the new thinner and lighter design, iPad has the same amazing 10-hour battery life.  That’s enough juice for one flight across the ocean, or one movie-watching all-nighter, or a week’s commute across town.  The power-efficient A5 chip and iOS keep battery life from fading away, so you can get carried away.<br><br><b>Two cameras.</b><br> You’ll see two cameras on iPad — one on the front and one on the back.  They may be tiny, but they’re a big deal.  They’re designed for FaceTime video calling, and they work together so you can talk to your favorite people and see them smile and laugh back at you. The front camera puts you and your friend face-to-face.  Switch to the back camera during your video call to share where you are, who you’re with, or what’s going on around you. When you’re not using FaceTime, let the back camera roll if you see something movie-worthy. It’s HD, so whatever you shoot is a mini-masterpiece. And you can take wacky snapshots in Photo Booth. It’s the most fun a face can have.<br><br><b>Due to the demand for this item, please allow up to 8-10 weeks for delivery</b>.',
                                 :points => '10927',
                                 :category => 'Office & Computer',
                                 :manufacturer => 'Apple',
                                 :small_image_url => 'https://www.rewardstation.com/catalogimages/MC769LLA.gif',
                                 :large_image_url => 'https://www.rewardstation.com/catalogimages/MC769LLA.jpg')
      end

      it "should not raise InvalidToken exception" do
        lambda{ service.return_popular_products(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

    describe "on create user invalid token request" do
      before { savon.stub(:return_popular_products).and_return(:return_popular_products_invalid_token) }

      it "should not raise InvalidToken exception" do
        lambda{ service.return_popular_products(130) }.should_not raise_error(RewardStation::InvalidToken)
      end
    end

  end

end