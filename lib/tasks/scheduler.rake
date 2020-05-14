desc "This task is called by the Heroku scheduler add-on"
task :scheduler => :environment do
  today = Date.today.strftime('%m%d').to_i
  time = Time.now + 9 * 60 * 60
  now = time.strftime("%H%M")
  wday = time.wday

  if [0, 6].include?(wday) && now.to_i > 800
    races = Race.where(date: today)

    if races.blank?
      Rake::Task['scrape:races'].invoke(today)

      races = Race.where(date: today)
      if races.present?
        Rake::Task['scrape:horses'].invoke(today)
        Rake::Task['scrape:quinella'].invoke(today)
        Rake::Task['scrape:quinella_place'].invoke(today)
        Rake::Task['scrape:exacta'].invoke(today)
      else
        puts '実行するスクリプトはありません'
      end
    else
      puts '実行するスクリプトはありません'
    end
  else
    puts '実行するスクリプトはありません'
  end
end
