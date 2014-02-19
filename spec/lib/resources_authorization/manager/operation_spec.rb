require 'spec_helper'


describe ResourcesAuthorization::Manager::Operation do
  before :each do
    User.delete_all
    @user = User.create

    Ability.delete_all
  end

  describe 'can' do
    it 'can read user, create ability record' do
      expect {
        Ability.can(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(1)

      a = Ability.first
      a.resource_identifer.should == User.to_resource_identifer.to_s
      a.abilities.should == ['+read']
      a.owner.should == @user
    end


    it 'can more times same operating, only create one record' do
      expect {
        Ability.can(@user, [Ability::WRITE], User)
        Ability.can(@user, [Ability::WRITE], User)
      }.to change(Ability, :count).by(1)
    end


    it 'nil can can, create record' do
      expect {
        Ability.can(nil, [Ability::READ], User)
      }.to change(Ability, :count).by(1)

      a = Ability.first
      a.owner.should == nil
      a.abilities.should == ['+read']
    end
  end

  describe 'cannot' do
    it 'cannot read user, create ability record' do
      expect {
        Ability.cannot(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(1)

      a = Ability.first
      a.resource_identifer.should == User.to_resource_identifer.to_s
      a.abilities.should == ['-read']
      a.owner.should == @user
    end


    it 'cannot more times same operating, only create one record' do
      expect {
        Ability.cannot(@user, [Ability::WRITE], User)
        Ability.cannot(@user, [Ability::WRITE], User)
      }.to change(Ability, :count).by(1)
    end


    it 'cannot set can abilit, + to -' do
      Ability.can(@user, [Ability::READ], User)
      a = Ability.first
      a.abilities.should == ['+read']

      expect {
        Ability.cannot(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(0)

      a.reload.abilities.should == ['-read']
    end


    it 'nil cannot, create record' do
      expect {
        Ability.cannot(nil, [Ability::READ], User)
      }.to change(Ability, :count).by(1)

      a = Ability.first
      a.owner.should == nil
      a.abilities.should == ['-read']
    end
  end

  describe 'clear' do
    it 'clear empty record, ok' do
      expect {
        Ability.clear(@user, [], User)
      }.to change(Ability, :count).by(0)

      expect {
        Ability.clear(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(0)
    end


    it 'clear can ability, remove can ability' do
      Ability.can(@user, [Ability::READ], User)
      a = Ability.first
      
      expect {
        Ability.clear(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(0)

      a.reload.abilities.should == []
    end


    it 'clear cannot ability, remove can not ability' do
      Ability.cannot(@user, [Ability::READ, Ability::WRITE], User)
      a = Ability.first
      a.abilities.sort.should == ['-read', '-write'].sort

      expect {
        Ability.clear(@user, [Ability::READ], User)
      }.to change(Ability, :count).by(0)
      a.reload.abilities.should == ['-write']
    end


    it 'clear nil ability, remove nil owner ability' do
      Ability.can(nil, [Ability::READ], User)
      a = Ability.first
      a.abilities.should == ['+read']

      Ability.clear(nil, [Ability::READ], User)
      a.reload.abilities.should == []
    end
  end

  describe 'can?' do
    before :each do
      Ability.can(@user, [Ability::READ], User)
      Ability.cannot(@user, [Ability::WRITE], User)
      Ability.can(nil, [Ability::READ], Ability)
    end

    it 'not exist ability, return nil' do
      Ability.can?(@user, Ability::OWN, User).should == nil
    end

    it 'exist - ability, return false' do
      Ability.can?(@user, Ability::WRITE, User).should == false
    end

    it 'exist + ability, return true' do
      Ability.can?(@user, Ability::READ, User).should == true
    end

    it 'record instance, can cover class ability' do
      Ability.can?(@user, Ability::WRITE, @user).should == false
      Ability.can(@user, [Ability::WRITE], @user)
      Ability.can?(@user, Ability::WRITE, @user).should == true
    end


    it 'other instance, can test' do
      Ability.can?(@user, Ability::READ, 'asdf').should == nil
      Ability.can(@user, [Ability::READ], 'asdf')
      Ability.can?(@user, Ability::READ, 'asdf').should == true
    end


    it 'all owner: nil, all owner can' do
      Ability.can?(nil, Ability::READ, Ability).should == true
      Ability.can?(@user, Ability::READ, Ability).should == true
    end


    it 'ability cover test' do
      Ability.delete_all

      Ability.can(nil, [Ability::READ], User)
      Ability.can?(@user, Ability::READ, @user).should == true

      Ability.cannot(nil, [Ability::READ], @user)
      Ability.can?(@user, Ability::READ, @user).should == false

      Ability.can(@user, [Ability::READ], User)
      Ability.can?(@user, Ability::READ, @user).should == true

      Ability.cannot(@user, [Ability::READ], @user)
      Ability.can?(@user, Ability::READ, @user).should == false
    end
  end
end
