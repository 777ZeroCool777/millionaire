require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  context 'game status' do

    it 'correct .variants' do

      expect(game_question.variants).to eq({
                                            'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                          })
    end

    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
    end

  end

  # help_hash у нас имеет такой формат:
  #   {
  #     fifty-fifty: ['a', 'b'], # При использовании подсказки остались варианты a и b
  #     audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #     friend_call: 'Василий Петрович считает, что правильный ответ A'
  #   }
  #

  context 'user helpers' do
    it 'correct audience_helper' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)
      expect(game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
    end

    it 'correct fifty_fifty' do
      expect(game_question.help_hash).not_to include(:fifty_fifty)

      v1 = game_question.variants.keys[1]
      v2 = game_question.variants.keys[0]

      game_question.add_fifty_fifty

      expect(game_question.help_hash).to include(:fifty_fifty)
      expect(
        game_question.help_hash[:fifty_fifty].to_a
      ).to contain_exactly(v1, v2)

      expect(game_question.help_hash[:fifty_fifty].size).to eq 2

    end

    it 'correct friend_call' do
      expect(game_question.help_hash).not_to include(:friend_call)

      game_question.add_friend_call

      expect(game_question.help_hash).to include(:friend_call)

      expect(
        game_question.help_hash[:friend_call]
      ).to include("считает, что это вариант")
    end

  end

  context '#correct_answer_key' do

    it 'true answer' do
      expect(game_question.correct_answer_key).to eq 'b'
    end
  end

end
