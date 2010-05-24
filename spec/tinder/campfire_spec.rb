require 'spec_helper'

describe Tinder::Campfire do
  context "when initializing" do
    context "when ssl is specified" do
      it "should set the base_uri to https if ssl is enabled" do
        campfire = Tinder::Campfire.new('test', :token => 'mytoken', :ssl => true)
        URI.parse(campfire.connection.base_uri).scheme.should == 'https'
      end

      it "should set the base_uri to http if ssl is not enabled" do
        campfire = Tinder::Campfire.new('test', :token => 'mytoken', :ssl => false)
        URI.parse(campfire.connection.base_uri).scheme.should == 'http'
      end
    end

    context "when ssl is not specified" do
      it "should auto-detect when ssl is enabled" do
        FakeWeb.register_uri(:get, "https://mytoken:X@test.campfirenow.com/users/me", :status => ["200", "OK"])
        campfire = Tinder::Campfire.new('test', :token => 'mytoken')
        URI.parse(campfire.connection.base_uri).scheme.should == 'https'
      end

      it "should auto-detect when ssl is not enabled" do
        FakeWeb.register_uri(:get, "https://mytoken:X@test.campfirenow.com/users/me", :status => ["302", "Found"],
          :location => "http://mytoken:X@test.campfirenow.com/users/me")
        campfire = Tinder::Campfire.new('test', :token => 'mytoken')
        URI.parse(campfire.connection.base_uri).scheme.should == 'http'
      end
    end
  end

  context "when initialized" do
    before do
      @campfire = Tinder::Campfire.new('test', :token => 'mytoken', :ssl => false)
    end

    describe "rooms" do
      before do
        FakeWeb.register_uri(:get, "http://mytoken:X@test.campfirenow.com/rooms.json",
          :body => fixture('rooms.json'), :content_type => "application/json")
      end

      it "should return rooms" do
        @campfire.rooms.size.should == 2
        @campfire.rooms.first.should be_kind_of(Tinder::Room)
      end

      it "should set the room name and id" do
        room = @campfire.rooms.first
        room.name.should == 'Room 1'
        room.id.should == 80749
      end
    end

    describe "users" do
      before do
        FakeWeb.register_uri(:get, "http://mytoken:X@test.campfirenow.com/rooms.json",
          :body => fixture('rooms.json'), :content_type => "application/json")
        [80749, 80751].each do |id|
          FakeWeb.register_uri(:get, "http://mytoken:X@test.campfirenow.com/room/#{id}.json",
          :body => fixture("rooms/room#{id}.json"), :content_type => "application/json")
        end
      end

      it "should return a sorted list of users in all rooms" do
        @campfire.users.length.should == 2
        @campfire.users.first[:name].should == "Jane Doe"
        @campfire.users.last[:name].should == "John Doe"
      end
    end

    describe "me" do
      before do
        FakeWeb.register_uri(:get, "http://mytoken:X@test.campfirenow.com/users/me.json",
          :body => fixture('users/me.json'), :content_type => "application/json")
      end

      it "should return the current user's information" do
        @campfire.me["name"].should == "John Doe"
      end
    end
  end
end
