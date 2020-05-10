desc "This task is called by the Heroku scheduler add-on"
task :scheduler => :environment do
  today = Date.today.strftime('%Y%m%d').to_i
  races = Race.where(date: today)

  if races.blank?
    Rake::Task['scrape:races'].invoke

    races = Race.where(date: today)
    if races.present?
      nankan_race_id = races.first.nankan_race_id.chop.chop

      Rake::Task['scrape:race_detail'].invoke(nankan_race_id)
      Rake::Task['scrape:horses'].invoke(nankan_race_id)
    else
      puts '実行するスクリプトはありません'
    end
  else
    nankan_race_list_id = races.first.nankan_race_id.chop.chop

    last_race = races.order(start_time: :desc).take
    now = (Time.now + 9 * 60 * 60).strftime('%H%M').to_i

    if now < last_race.start_time && 1000 < now
      Rake::Task['scrape:odds'].invoke(nankan_race_list_id)
    else
      puts '実行するスクリプトはありません'
    end
  end
end
