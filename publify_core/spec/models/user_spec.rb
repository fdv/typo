# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "FactoryBot Bot" do
    it "users factory valid" do
      expect(create(:user)).to be_valid
      expect(build(:user)).to be_valid
    end

    it "multiples user factory valid" do
      expect(create(:user)).to be_valid
      expect(create(:user)).to be_valid
    end

    it "salt should not be nil" do
      expect(described_class.salt).to eq("20ac4d290c2293702c64b3b287ae5ea79b26a5c1")
    end
  end

  describe "#active_for_authentication?" do
    it "is true for users in the state 'active'" do
      user = build :user, state: "active"
      expect(user).to be_active_for_authentication
    end

    it "is false for users in the state 'inactive'" do
      user = build :user, state: "inactive"
      expect(user).not_to be_active_for_authentication
    end
  end

  context "With the contents and users fixtures loaded" do
    it "The various article finders work appropriately" do
      create(:blog)
      tobi = create(:user)
      create_list(:article, 7, user: tobi)
      create(:article, state: "draft", published_at: nil, user: tobi)
      expect(tobi.articles.size).to eq(8)
      expect(tobi.articles.published.size).to eq(7)
    end
  end

  describe "With a new user" do
    before do
      @user = build :user, login: "not_bob", email: "publify@publify.com"
    end

    describe "the login" do
      it "can be just right" do
        @user.login = "okbob"
        expect(@user).to be_valid
      end

      { "too short" => "x",
        "too long" => "repetitivepass" * 10,
        "empty" => "" }.each do |problematic, login|
        it "cannot be #{problematic}" do
          @user.login = login
          expect(@user).not_to be_valid
          expect(@user.errors["login"]).to be_any
        end
      end
    end

    it "email cannot be blank" do
      @user.email = ""
      expect(@user).not_to be_valid
    end

    describe "#display_name" do
      it "is not blank" do
        expect(@user.display_name).not_to be_empty
      end
    end
  end

  describe "With a user in the database" do
    before do
      @olduser = create(:user)
    end

    it "is not able to create another user with the same login" do
      login = @olduser.login
      new_user = described_class.new(login: login) do |u|
        u.password = u.password_confirmation = "secure password"
      end

      expect(new_user).not_to be_valid
      expect(new_user.errors["login"]).not_to be_empty
    end
  end

  describe "Updating an existing user" do
    before do
      @user = create(:user)
    end

    describe "the login" do
      it "must not change" do
        @user.email = "not_bob"
        expect(@user).not_to be_valid
      end
    end
  end

  describe "#initialize" do
    it "accepts a settings field in its parameter hash" do
      described_class.new("firstname" => "foo")
    end
  end

  describe "#admin?" do
    it "returns true if user is admin" do
      admin = build(:user, :as_admin)
      expect(admin).to be_admin
    end

    it "returns false if user is not admin" do
      publisher = build(:user, :as_publisher)
      expect(publisher).not_to be_admin
    end
  end

  describe "#first_and_last_name" do
    context "with first and last name" do
      let(:user) { create(:user, firstname: "Marlon", lastname: "Brando") }

      it { expect(user.first_and_last_name).to eq("Marlon Brando") }
    end

    context "with firstname without lastname" do
      let(:user) { create(:user, firstname: "Marlon", lastname: nil) }

      it { expect(user.first_and_last_name).to eq("") }
    end
  end

  describe "#display_names" do
    context "with user without nickname, firstname, lastname" do
      let(:user) { create(:user, nickname: nil, firstname: nil, lastname: nil) }

      it { expect(user.display_names).to eq([user.login]) }
    end

    context "with user with nickname without firstname, lastname" do
      let(:user) { create(:user, nickname: "Bob", firstname: nil, lastname: nil) }

      it { expect(user.display_names).to eq([user.login, user.nickname]) }
    end

    context "with user with firstname, without nickname, lastname" do
      let(:user) { create(:user, nickname: nil, firstname: "Robert", lastname: nil) }

      it { expect(user.display_names).to eq([user.login, user.firstname]) }
    end

    context "with user with lastname, without nickname, firstname" do
      let(:user) { create(:user, nickname: nil, firstname: nil, lastname: "Redford") }

      it { expect(user.display_names).to eq([user.login, user.lastname]) }
    end

    context "with user with firstname and lastname, witjout nickname" do
      let(:user) { create(:user, nickname: nil, firstname: "Robert", lastname: "Redford") }

      it {
        expect(user.display_names).
          to eq([user.login, user.firstname, user.lastname,
                 "#{user.firstname} #{user.lastname}"])
      }
    end
  end

  describe "#has_twitter_configured?" do
    it "is false without twitter_oauth_token or twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: nil, twitter_oauth_token_secret: nil)
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with an empty twitter_oauth_token and no twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: "", twitter_oauth_token_secret: nil)
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with empty twitter_oauth_token and twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: "", twitter_oauth_token_secret: "")
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with a twitter_oauth_token and no twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: "12345", twitter_oauth_token_secret: nil)
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with a twitter_oauth_token and an empty twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: "12345", twitter_oauth_token_secret: "")
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with a twitter_oauth_token_secret and no twitter_oauth_token" do
      user = build(:user, twitter_oauth_token: "", twitter_oauth_token_secret: "67890")
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is false with a twitter_oauth_token_secret and an empty twitter_oauth_token" do
      user = build(:user, twitter_oauth_token_secret: "67890", twitter_oauth_token: "")
      expect(user.has_twitter_configured?).to eq(false)
    end

    it "is true with a twitter_oauth_token and a twitter_oauth_token_secret" do
      user = build(:user, twitter_oauth_token: "12345", twitter_oauth_token_secret: "67890")
      expect(user.has_twitter_configured?).to eq(true)
    end
  end
end
