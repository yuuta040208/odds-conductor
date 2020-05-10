require 'nokogiri'
require 'open-uri'
require 'kconv'

URL = 'https://keiba.yahoo.co.jp/'
SLEEP_SECOND = 5

namespace :scrape do
  desc 'レース情報をスクレイピング'
  task :races, ['date'] => :environment do |_, args|
    date = args['date']

    if date.present?
      month = date.slice(0..1).to_i
      day = date.slice(2..3).to_i
      url = File.join(URL, 'schedule/list/', Date.today.year.to_s, "?month=#{month}")
      html = open(url).read
      doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

      paths = []
      doc.css('table.scheLs.mgnBS tr').each do |tr|
        a = tr.css('td:nth-child(1) a')
        if a.present?
          if day == tr.css('td:nth-child(1)').text.split('日').first.to_i
            paths << a.first[:href]
          end
        end
      end

      ActiveRecord::Base.transaction do
        paths.each do |path|
          (1..12).each do |number|
            race = Race.create!(
                date: date,
                place: Settings.places[path.split('/')[-1].slice(2..3).to_i],
                time: path.split('/')[-1].slice(4..5).to_i,
                day: path.split('/')[-1].slice(6..7).to_i,
                number: number,
                url: path.gsub('list', 'denma').chop + format('%02d', number)
            )

            puts "#{race.url}"
          end
        end
      end
    else
      puts '日付を指定して実行してください。'
    end
  end


  desc '競走馬と単勝・複勝オッズをスクレイピング'
  task :horses, ['date'] => :environment do |_, args|
    date = args['date']

    if date.present?
      Race.where(date: date).each do |race|
        url = File.join(URL, 'odds/tfw', race.url.split('/').last, '/')
        html = open(url).read
        doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

        ActiveRecord::Base.transaction do
          doc.css('div.layoutCol2L > table tr').each_with_index do |tr, index|
            next if index.zero?

            horse = Horse.create!(
                race_id: race.id,
                number: tr.css('td:nth-child(2)').text.to_i,
                name: tr.css('td:nth-child(3)').text,
                win: tr.css('td:nth-child(4)').text.to_f,
                place: ((tr.css('td:nth-child(5)').text.to_f + tr.css('td:nth-child(7)').text.to_f) / 2).round(1)
            )

            puts "#{horse.name} - win: #{horse.win}, place: #{horse.place}"
          end

          doc.css('div.layoutCol2R > table tr').each_with_index do |tr, index|
            next if index.zero?

            horse = Horse.create!(
                race_id: race.id,
                number: tr.css('td:nth-child(2)').text.to_i,
                name: tr.css('td:nth-child(3)').text,
                win: tr.css('td:nth-child(4)').text.to_f,
                place: ((tr.css('td:nth-child(5)').text.to_f + tr.css('td:nth-child(7)').text.to_f) / 2).round(1)
            )

            puts "#{horse.name} - win: #{horse.win}, place: #{horse.place}"
          end
        end

        ActiveRecord::Base.transaction do
          horses = race.horses
          horses.each do |horse|
            (1..horses.size).each do |index|
              if horse.number != index
                Odds.create!(race_id: race.id, first_horse_number: horse.number, second_horse_number: index)
              end
            end
          end
        end

        sleep(SLEEP_SECOND)
      end
    else
      puts '日付を指定して実行してください。'
    end
  end

  desc '馬連オッズをスクレイピング'
  task :quinella, ['date'] => :environment do |_, args|
    date = args['date']

    if date.present?
      Race.where(date: date).each do |race|
        url = File.join(URL, 'odds/ur', race.url.split('/').last, '/')
        html = open(url).read
        doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

        ActiveRecord::Base.transaction do
          doc.css('table.oddsLs').each do |table|
            first_horse_number = 0

            table.css('tr').each_with_index do |tr, index|
              if index.zero?
                first_horse_number = tr.text.to_i
                next
              end

              first_horse = race.horses.find_by(number: first_horse_number)
              second_horse = race.horses.find_by(number: tr.css('th').text.to_i)

              first_odds = Odds.find_by(race_id: race.id, first_horse_number: first_horse.number, second_horse_number: second_horse.number)
              first_odds.quinella = tr.css('td:nth-child(2)').text.to_f
              first_odds.save!

              second_odds = Odds.find_by(race_id: race.id, first_horse_number: second_horse.number, second_horse_number: first_horse.number)
              second_odds.quinella = tr.css('td:nth-child(2)').text.to_f
              second_odds.save!

              puts "#{first_horse.number}.#{first_horse.name} - #{second_horse.number}.#{second_horse.name}: #{first_odds.quinella}"
            end
          end
        end

        sleep(SLEEP_SECOND)
      end
    else
      puts '日付を指定して実行してください。'
    end
  end

  desc 'ワイドオッズをスクレイピング'
  task :quinella_place, ['date'] => :environment do |_, args|
    date = args['date']

    if date.present?
      Race.where(date: date).each do |race|
        url = File.join(URL, 'odds/wide', race.url.split('/').last, '/')
        html = open(url).read
        doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

        ActiveRecord::Base.transaction do
          doc.css('table.oddsWLs').each do |table|
            first_horse_number = 0

            table.css('tr').each_with_index do |tr, index|
              if index.zero?
                first_horse_number = tr.text.to_i
                next
              end

              first_horse = race.horses.find_by(number: first_horse_number)
              second_horse = race.horses.find_by(number: tr.css('th').text.to_i)

              first_odds = Odds.find_by(race_id: race.id, first_horse_number: first_horse.number, second_horse_number: second_horse.number)
              first_odds.quinella_place = ((tr.css('td:nth-child(2)').text.to_f + tr.css('td:nth-child(4)').text.to_f) / 2).round(1)
              first_odds.save!

              second_odds = Odds.find_by(race_id: race.id, first_horse_number: second_horse.number, second_horse_number: first_horse.number)
              second_odds.quinella_place = ((tr.css('td:nth-child(2)').text.to_f + tr.css('td:nth-child(4)').text.to_f) / 2).round(1)
              second_odds.save!

              puts "#{first_horse.number}.#{first_horse.name} - #{second_horse.number}.#{second_horse.name}: #{second_odds.quinella_place}"
            end
          end
        end

        sleep(SLEEP_SECOND)
      end
    else
      puts '日付を指定して実行してください。'
    end
  end

  desc '馬単オッズをスクレイピング'
  task :exacta, ['date'] => :environment do |_, args|
    date = args['date']

    if date.present?
      Race.where(date: date).each do |race|
        url = File.join(URL, 'odds/ut', race.url.split('/').last, '/')
        html = open(url).read
        doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

        ActiveRecord::Base.transaction do
          doc.css('table.oddsLs').each do |table|
            first_horse_number = 0

            table.css('tr').each_with_index do |tr, index|
              if index.zero?
                first_horse_number = tr.text.to_i
                next
              end

              first_horse = race.horses.find_by(number: first_horse_number)
              second_horse = race.horses.find_by(number: tr.css('th').text.to_i)

              first_odds = Odds.find_by(race_id: race.id, first_horse_number: first_horse.number, second_horse_number: second_horse.number)
              first_odds.exacta = tr.css('td:nth-child(2)').text.to_f
              first_odds.save!

              second_odds = Odds.find_by(race_id: race.id, first_horse_number: second_horse.number, second_horse_number: first_horse.number)
              second_odds.exacta = tr.css('td:nth-child(2)').text.to_f
              second_odds.save!

              puts "#{first_horse.number}.#{first_horse.name} - #{second_horse.number}.#{second_horse.name}: #{first_odds.exacta}"
            end
          end
        end

        sleep(SLEEP_SECOND)
      end
    else
      puts '日付を指定して実行してください。'
    end
  end
end
