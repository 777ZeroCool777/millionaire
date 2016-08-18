require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do

  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  context 'Anon' do
    it 'kick from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #create' do
      post :create

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #answer' do
      get :answer, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #take_money' do
      put :take_money, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #help' do
      put :help, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

  end

  # группа тестов на экшены контроллера, доступным залогиненым юзерам
  context 'Usual user' do

    before(:each) do
      sign_in user
    end

    it 'creates game' do
      generate_questions(60)

      post :create

      game = assigns(:game)

      # проверяю состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response).to redirect_to game_path(game)
      expect(flash[:notice]).to be
    end

    # юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера полк @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show')
    end

    it 'answer correct' do
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end

    # тест на отработку "помощи зала"
    it 'user audience  help' do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    # тест на то, что пользователь не может смотреть чужую игру
    it 'not current show game' do

      fake_user = FactoryGirl.create(:game_with_questions)

      get :show, id: fake_user.id

      expect(response.status).not_to eq(200)
    end

    # проверка, что пользователь не может начать игру пока не закончит первую
    it 'user dont have second game' do
      generate_questions(60)

      post :create

      game1 = assigns(:game)

      # проверяю состояние этой игры
      expect(game1.finished?).to be_falsey
      expect(game1.user).to eq(user)

      expect(response).to redirect_to game_path(game1)
      expect(flash[:notice]).to be

      post :create

      fake_game = assigns(:game)

      expect(response).to redirect_to game_path(game1)
      expect(flash[:alert]).to eq I18n.t('controllers.games.game_not_finished')
      expect(fake_game.id).to eq game1.id
    end

    # проверка, когда пользователь берет лаве
    it '#take_money controller' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      put :take_money, id: game_w_questions.id

      game = assigns(:game)

      expect(game.finished?).to be_truthy

      expect(response).to redirect_to user_path(user)
      expect(flash[:warning]).to be

    end

    # проверка, неправильного ответа игрока
    it 'not correct answer' do
      game_w_questions.current_game_question.update_attributes(a: 1, b: 2, c: 3, d: 4)
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.variants.keys[3]

      game = assigns(:game)

      expect(game.finished?).to be_truthy

      expect(flash[:alert]).to be

      expect(response).to redirect_to user_path(user)
    end

    # проверка, что игрок может заюзать подсказку  50/50
    it '50/50' do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty_used]).not_to be

      expect(put :help, id: game_w_questions.id, help_type: :fifty_fifty_used).to be
    end
  end

end
