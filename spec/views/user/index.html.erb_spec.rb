require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Владик', balance: 5),
      FactoryGirl.build_stubbed(:user, name: 'Вадик', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Миша', balance: 3000)
    ])

    render
  end

  it 'render player names' do
    expect(rendered).to match 'Вадик'
    expect(rendered).to match 'Миша'
    expect(rendered).to match 'Владик'
  end

  it 'render player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
    expect(rendered).to match '5 ₽'
  end

  it 'render player names in right order' do
    expect(rendered).to match /Вадик.*Миша/m
  end
end