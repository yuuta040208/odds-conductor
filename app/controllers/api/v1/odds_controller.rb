class Api::V1::OddsController < Api::V1::ApplicationController
  def show
    if params[:place].present? && params[:time].present? && params[:day].present? && params[:number].present?
      race = Race.find_by(place: params[:place], time: params[:time], day: params[:day], number: params[:number])

      if race.present? && race.horses.present?
        @horses = race.horses

        begin
          body = JSON.parse(request.body.read)
          if body['odds'].values.sum <= 1.0

            render json: bets(race, body['odds'], body['budget']).to_json
          else
            render json: {error: true, message: 'データ形式が無効です。'}
          end
        rescue
          render json: {error: true, message: 'データ形式が無効です。'}
        end
      else
        render json: {error: true, message: 'データが存在しません。'}
      end
    else
      render json: {error: true, message: 'パラメータが無効です。'}
    end
  end


  private

  def bets(race, body, budget)
    odds = race.odds

    bets = {}
    bet_body = body.map {|a, b| [a.to_i, (b * budget).round(0)]}.sort_by {|a| a.second}.reverse.select {|_, b| !b.zero?}

    bet_body.each do |horse_number, bet_max|
      except_bet_body = bet_body.select {|a, _| a != horse_number}
      sum = except_bet_body.sum {|_, b| b}
      bet_counts = except_bet_body.map {|a, b| [a, (b.to_f / sum * bet_max).ceil(0)]}.select {|_, b| !b.zero?}

      temp_count = 0
      bet_counts = bet_counts.select do |_, b|
        temp_count = temp_count + b
        temp_count <= bet_max
      end

      bet_counts.each do |a, b|
        numbers = [horse_number, a].sort.join('-')

        if bets[numbers].present?
          bet = bets[numbers]
          bets[numbers] = {
              count: b + bet[:count],
              value: (b * odds.find_by(first_horse_id: horse_number, second_horse_id: a).quinella * 100).round(0) + bet[:value]
          }
        else
          bets[numbers] = {
              count: b,
              value: (b * odds.find_by(first_horse_id: horse_number, second_horse_id: a).quinella * 100).round(0)
          }
        end
      end
    end

    {bets: bets, total: bets.values.sum {|a| a[:count]}}
  end
end
