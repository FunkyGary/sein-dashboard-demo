class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :fbinformation, :only => [:index, :facebook]
  before_action :gainformation, :only => [:index, :googleanalytics]

  def create
    if params[:starttime]
      @starttime = params[:starttime].to_date.strftime("%Y-%m-%d")
      @endtime = (params[:endtime].to_date + 1).strftime("%Y-%m-%d")
      @fb_end = (params[:endtime].to_date + 1).strftime("%Y-%m-%d")
      @fb_start = (params[:starttime].to_date).strftime("%Y-%m-%d")

      @fb = FbDb.where(date: @fb_start..@fb_end)
      @ga = GaDb.where(date: @starttime..@endtime)
      @mailchimp = MailchimpDb.where(date: @starttime..@endtime)
      puts @mailchimp

      unless @mailchimp.empty?
        @mail_users_select = @mailchimp.last.email_sent
        @mail_users_last_select = @mailchimp.pluck(:email_sent)
        @mail_users_select_rate = convert_percentrate(@mail_users_select, @mailchimp.first.email_sent)
        @mail_views_rate_select = @mailchimp.pluck(:open_rate).map { |a| a.round(2) }
        @mail_links_rate_select = @mailchimp.pluck(:click).zip(@mailchimp.pluck(:open)).map { |a, b| (a / b.to_f).round(2) }
        @select_date = @mailchimp.pluck(:date).map { |a| a.strftime("%m%d").to_i }
      end

      # 粉絲專頁讚數
      @fans_adds_last_select = @fb.pluck(:fans_adds_day)
      @fans_adds_select_rate = convert_percentrate(@fb.last.fans_adds_day, @fb.first.fans_adds_day)

      # 粉專曝光使用者
      @page_users_select = @fb.pluck(:page_users_day).reduce(:+)
      @page_users_last_select = @fb.pluck(:page_users_day)
      @page_users_select_rate = convert_percentrate(@page_users_select, @fb.first.page_users_day) 

      # 官網使用者
      @web_users_select = @ga.pluck(:web_users_day).reduce(:+)
      @web_users_last_select = @ga.pluck(:web_users_day)
      @web_users_select_rate = convert_percentrate(@web_users_select, @ga.first.web_users_day)

      # 官網流量來源與跳出率分析
      @channel_user_select = ga_preprocess(@ga.pluck(:oganic_search_day), @ga.pluck(:social_user_day), @ga.pluck(:direct_user_day), @ga.pluck(:referral_user_day), @ga.pluck(:email_user_day))
      @bounce_rate_select = ga_preprocess_rate(@ga.pluck(:oganic_search_bounce), @ga.pluck(:social_bounce), @ga.pluck(:direct_bounce), @ga.pluck(:referral_bounce), @ga.pluck(:email_bounce))

      # 粉專貼文觸及
      @posts_users_select = @fb.pluck(:posts_users_day).reduce(:+)
      @posts_users_last_select_day = @fb.pluck(:posts_users_day)
      @posts_users_last_select_week = @fb.pluck(:posts_users_day)
      @posts_users_select_rate = convert_percentrate(@posts_users_select, @fb.first.posts_users_day) 

      # 粉專負面行動人數
      @negative_users_select = @fb.pluck(:negative_users_day).reduce(:+)
      @negative_users_last_select = @fb.pluck(:negative_users_day)
      @negative_users_select_rate = convert_percentrate(@negative_users_select, @fb.first.negative_users_day) 

      # 官網瀏覽量
      @pageviews_select = @ga.pluck(:pageviews_day).reduce(:+)
      @pageviews_last_select = @ga.pluck(:pageviews_day)
      @pageviews_select_rate = convert_percentrate(@pageviews_select, @ga.first.pageviews_day)
      
      # 官網平均瀏覽頁數
      @pageviews_per_session_select = (@ga.pluck(:pageviews_per_session_day).reduce(:+) / @ga.pluck(:pageviews_per_session_day).size).round(2)
      @pageviews_per_session_last_select = @ga.pluck(:pageviews_per_session_day).map { |i| i.round(2) }
      @pageviews_per_session_select_rate = convert_percentrate(@pageviews_per_session_select, @ga.first.pageviews_per_session_day)  

      # 官網平均停留時間
      @avg_session_duration_select = (@ga.pluck(:avg_session_duration_day).reduce(:+) / @ga.pluck(:avg_session_duration_day).size).round(2)
      @avg_session_duration_last_select = @ga.pluck(:avg_session_duration_day).flat_map { |i| i.round(2) }
      @avg_session_duration_week_rate = convert_percentrate(@avg_session_duration_select, @ga.first.avg_session_duration_day)

      # [created_time, message, like, comment, share, interact]
      posts = []

      FbPostDb.each do |d|

        unless d["message"].nil?
          like = d.like
          comment = d.comment
          share = d.share

          posts << [date, message, interact]
        end
      end

      posts.sort_by! { |item|
        -item[2]
      }

      @select_top_posts = posts.first(5)

      if (@endtime.to_date - @starttime.to_date) > 20
        @posts_users_last_select = []
        @enagements_users_last_select = []
        @fb_last_select = []
        @all_users_views_last_select = []
        @activeusers_views_last_select = []
        @ga_last_select_date = []
        @post_enagements_last_select = []
        @link_clicks_last_select = []
        @fans_adds_last_select_week = []
        @fans_losts_last_select = []

        data = @fb.size
        @ga = GaDb.where(date: ((@starttime.to_date + data % 7 - 7).strftime("%Y-%m-%d"))..@endtime)

        if (data % 7).zero?
          start = 6
        else
          start = (data % 7) - 1
        end
        (start).step(data, 7) { |i| 
          # 粉絲黏著度分析
          @posts_users_last_select_week << @fb.pluck(:posts_users_week)[i]
          @enagements_users_last_select << @fb.pluck(:enagements_users_week)[i]

          # 貼文點擊分析
          @post_enagements_last_select << @fb.pluck(:post_enagements_week)[i]
          @link_clicks_last_select << @fb.pluck(:link_clicks_week)[i]
          
          # 粉專讚數趨勢
          @fans_adds_last_select_week << @fb.pluck(:fans_adds_week)[i]
          @fans_losts_last_select << @fb.pluck(:fans_losts_week)[i]

          # 日期(fb的日期為到期日的早上七點 所以減一才是那天的值)
          @fb_last_select << @fb.pluck(:date).map { |a| (a.to_date - 1).strftime("%m%d").to_i }[i]

          # 官網瀏覽活躍度分析
          @all_users_views_last_select << @ga.pluck(:pageviews_day)[i - data % 7 + 1..i - data % 7 + 7].reduce(:+)
          @activeusers_views_last_select << @all_users_views_last_select.last - @ga.pluck(:single_session)[i - data % 7 + 1..i - data % 7 + 7].reduce(:+)

          # 日期
          @ga_last_select_date << @ga.pluck(:date).map { |a| a.strftime("%m%d").to_i }[i - data % 7 + 7]
        }
      else
        # 粉絲黏著度分析
        @posts_users_last_select_day = @fb.pluck(:posts_users_day)
        @enagements_users_last_select = @fb.pluck(:enagements_users_day)
        
        # 貼文點擊分析
        @post_enagements_last_select = @fb.pluck(:post_enagements_day)
        @link_clicks_last_select = @fb.pluck(:link_clicks_day)
        
        # 粉專讚數趨勢
        @fans_adds_last_select_week = @fb.pluck(:fans_adds_day)
        @fans_losts_last_select = @fb.pluck(:fans_losts_day)

        # 日期(fb的日期為到期日的早上七點 所以減一才是那天的值)
        @fb_last_select = @fb.pluck(:date).map { |a| (a - 1).strftime("%m%d").to_i }

        # 官網瀏覽活躍度分析
        @all_users_views_last_select = @ga.pluck(:pageviews_day)
        @activeusers_views_last_select = @all_users_views_last_select.zip(@ga.pluck(:single_session)).map { |k| (k[0] - k[1]) }
        
        # 日期
        @ga_last_select_date = @ga.pluck(:date).map { |a| a.strftime("%m%d").to_i }
      end

      @fans_retention_rate_select = @enagements_users_last_select.zip(@posts_users_last_select_week).map { |x, y| (x / y.to_f).round(2) }
      @users_activity_rate_select = @activeusers_views_last_select.zip(@all_users_views_last_select).map { |x, y| (x / y.to_f).round(2) }
      @link_clicks_rate_select = @link_clicks_last_select.zip(@post_enagements_last_select).map { |x, y| (x / y.to_f).round(2) }

      render :json => { 
        :mail_users_select => @mail_users_select, :mail_users_last_select => @mail_users_last_select, 
        :mail_users_select_rate => @mail_users_select_rate, :mail_views_rate_select => @mail_views_rate_select, 
        :mail_links_rate_select => @mail_links_rate_select, :select_date => @select_date, 
        :fans_adds_last_select => @fans_adds_last_select, :fans_adds_select_rate => @fans_adds_select_rate, 
        :page_users_select => @page_users_select, :page_users_last_select => @page_users_last_select, 
        :page_users_select_rate => @page_users_select_rate, :posts_users_last_select_day => @posts_users_last_select_day, 
        :enagements_users_last_select => @enagements_users_last_select, :fans_retention_rate_select => @fans_retention_rate_select, 
        :fb_last_select => @fb_last_select, :web_users_select => @web_users_select, 
        :web_users_last_select => @web_users_last_select, :web_users_select_rate => @web_users_select_rate, 
        :all_users_views_last_select => @all_users_views_last_select, :activeusers_views_last_select => @activeusers_views_last_select, 
        :users_activity_rate_select => @users_activity_rate_select, :ga_last_select_date => @ga_last_select_date, 
        :channel_user_select => @channel_user_select, :bounce_rate_select => @bounce_rate_select, 
      # FB
        :posts_users_select => @posts_users_select, :posts_users_select_rate => @posts_users_select_rate,
        :negative_users_select => @negative_users_select, :negative_users_last_select => @negative_users_last_select, :negative_users_select_rate => @negative_users_select_rate,
        :fans_adds_last_select_week => @fans_adds_last_select_week, :fans_losts_last_select => @fans_losts_last_select, 
        :post_enagements_last_select => @post_enagements_last_select, :link_clicks_last_select => @link_clicks_last_select, :link_clicks_rate_select => @link_clicks_rate_select,
        :select_top_posts => @select_top_posts, :posts_users_last_select_week => @posts_users_last_select_week,
      # GA  
        :pageviews_select => @pageviews_select, :pageviews_last_select => @pageviews_last_select, :pageviews_select_rate => @pageviews_select_rate,
        :pageviews_per_session_select => @pageviews_per_session_select, :pageviews_per_session_last_select => @pageviews_per_session_last_select, :pageviews_per_session_select_rate => @pageviews_per_session_select_rate,
        :avg_session_duration_select => @avg_session_duration_select, :avg_session_duration_last_select => @avg_session_duration_last_select, :avg_session_duration_week_rate => @avg_session_duration_week_rate
      }
    end
  end

  def index
    # 電子報訂閱數
    @mail_users = MailchimpDb.last.email_sent

    # 電子報訂閱數折線圖
    @mail_users_last_30d = MailchimpDb.last(4).pluck(:email_sent)

    # 電子報訂閱數比例
    @mail_users_month_rate = convert_percentrate(MailchimpDb.last(4).first.email_sent - @mail_users, MailchimpDb.last(12).first.email_sent - MailchimpDb.last(8).first.email_sent)

    # 電子報成效分析
    # 開信率
    @mail_views_rate = MailchimpDb.last(4).pluck(:open_rate).map { |a| a.round(2) }

    # 連結點擊率
    @mail_links_rate = MailchimpDb.last(4).pluck(:click_rate).map { |a| a.round(2) }

    # 日期
    @last_12w_date = MailchimpDb.last(4).pluck(:date).map { |a| a.strftime("%m%d").to_i }
    
    # 競爭對手流量分析
    # 排名
    @rank = AlexaDb.last(1).pluck(:womany_rank, :pansci_rank, :newsmarket_rank, :einfo_rank, :sein_rank, :npost_rank)[0]

    # 跳出率
    @rate = AlexaDb.last(1).pluck(:womany_bounce_rate, :pansci_bounce_rate, :newsmarket_bounce_rate, :einfo_bounce_rate, :sein_bounce_rate, :npost_bounce_rate)[0].map { |a| a.round(2) }

    # 日期
    @created_at = AlexaDb.last.created_at.strftime("%Y-%m-%d")
  end

  def facebook
    # 粉專貼文觸及人數
    @posts_users_week = FbDb.last.posts_users_week
    @posts_users_month = FbDb.last.posts_users_month 

    # 粉專貼文觸及人數折線圖
    @posts_users_last_30d = FbDb.last(28).pluck(:posts_users_day)
    @posts_users_last_7d = @posts_users_last_30d.last(7)
    
     # 粉專貼文觸及人數比例
    @posts_users_week_rate = convert_percentrate(@posts_users_week, FbDb.last(8).first.posts_users_week) 
    @posts_users_month_rate = convert_percentrate(@posts_users_month, FbDb.last(29).first.posts_users_month)

    # 粉專負面行動人數
    @negative_users_week = FbDb.last.negative_users_week
    @negative_users_month = FbDb.last.negative_users_month

    # 粉專負面行動人數折線圖
    @negative_users_last_30d = FbDb.last(28).pluck(:negative_users_day)
    @negative_users_last_7d = @negative_users_last_30d.last(7)

    # 粉專負面行動人數比例
    @negative_users_week_rate = convert_percentrate(@negative_users_week, FbDb.last(7).first.negative_users_week) 
    @negative_users_month_rate = convert_percentrate(@negative_users_month, FbDb.last(29).first.negative_users_month)

    # 貼文點擊分析
    # 貼文互動總數
    @post_enagements_last_7d = FbDb.last(7).pluck(:post_enagements_day)
    @post_enagements_last_4w = FbDb.last(22).pluck(:post_enagements_week).values_at(0, 7, 14, 21)
    
    # 連結點擊數
    @link_clicks_last_7d = FbDb.last(7).pluck(:link_clicks_day)
    @link_clicks_last_4w = FbDb.last(22).pluck(:link_clicks_week).values_at(0, 7, 14, 21)

    # 連結點擊率
    @link_clicks_rate_7d = @link_clicks_last_7d.zip(@post_enagements_last_7d).map { |x, y| (x / y.to_f).round(2) }
    @link_clicks_rate_30d = @link_clicks_last_4w.zip(@post_enagements_last_4w).map { |x, y| (x / y.to_f).round(2) }

    # 粉專讚數趨勢
    # 淨讚數
    @fans_adds_last_4w = FbDb.last(22).pluck(:fans_adds_week).values_at(0, 7, 14, 21)

    # 退讚數
    @fans_losts_last_7d = FbDb.last(7).pluck(:fans_losts_day)
    @fans_losts_last_4w = FbDb.last(22).pluck(:fans_losts_week).values_at(0, 7, 14, 21)
    
    i = 1
    while FbDb.last(i).first.fans_female_day.nil?
      i += 1
    end

    # 粉絲男女比例
    @fans_female_day = FbDb.last(i).first.fans_female_day
    @fans_male_day = FbDb.last(i).first.fans_male_day

    # 粉絲年齡分佈
    @fans_age = []

    @fans_age << FbDb.last(i).first.fans_13_17 
    @fans_age << FbDb.last(i).first.fans_18_24 
    @fans_age << FbDb.last(i).first.fans_25_34 
    @fans_age << FbDb.last(i).first.fans_35_44 
    @fans_age << FbDb.last(i).first.fans_45_54 
    @fans_age << FbDb.last(i).first.fans_55_64 
    @fans_age << FbDb.last(i).first.fans_65
   
    # 臉書貼文

    @month_top_posts = FbPostDb.first(20).values_at(0, 11, 14, 12, 5)
    @week_top_posts = FbPostDb.first(10).values_at(0, 5, 8, 2, 1)
    
  end

  def googleanalytics
    # 官網瀏覽量
    @pageviews_week = GaDb.last(7).pluck(:pageviews_day).reduce(:+)
    @pageviews_month = GaDb.last(28).pluck(:pageviews_day).reduce(:+)

    # 官網瀏覽量折線圖
    @pageviews_last_30d = GaDb.last(28).pluck(:pageviews_day)
    @pageviews_last_7d = @pageviews_last_30d.last(7)

    # 官網瀏覽量比例
    @pageviews_week_rate = convert_percentrate(@pageviews_week, GaDb.last(14).first(7).pluck(:pageviews_day).reduce(:+))  
    @pageviews_month_rate = convert_percentrate(@pageviews_month, GaDb.last(56).first(28).pluck(:pageviews_day).reduce(:+))
    
    # 官網平均瀏覽頁數
    @pageviews_per_session_week = ((GaDb.last(7).pluck(:pageviews_per_session_day).reduce(:+)) / 7).round(2)
    @pageviews_per_session_month = ((GaDb.last(28).pluck(:pageviews_per_session_day).reduce(:+)) / 28).round(2)
    
    # 官網平均瀏覽頁數折線圖
    @pageviews_per_session_30d = GaDb.last(28).pluck(:pageviews_per_session_day).map { |i| i.round(2) }
    @pageviews_per_session_7d = @pageviews_per_session_30d.last(7)

    # 官網平均瀏覽頁數比例
    @pageviews_per_session_week_rate = convert_percentrate(@pageviews_per_session_week, (GaDb.last(14).first(7).pluck(:pageviews_per_session_day).reduce(:+) / 7).round(2))  
    @pageviews_per_session_month_rate = convert_percentrate(@pageviews_per_session_month, (GaDb.last(56).first(28).pluck(:pageviews_per_session_day).reduce(:+) / 28).round(2))  

    # 官網平均停留時間
    @avg_session_duration_week = ((GaDb.last(7).pluck(:avg_session_duration_day).reduce(:+)) / 7).round(2)
    @avg_session_duration_month = ((GaDb.last(28).pluck(:avg_session_duration_day).reduce(:+)) / 28).round(2)

    # 官網平均停留時間折線圖
    @avg_session_duration_30d = GaDb.last(28).pluck(:avg_session_duration_day).flat_map { |i| i.round(2) }
    @avg_session_duration_7d = @avg_session_duration_30d.last(7)
    
    # 官網平均停留時間比例
    @avg_session_duration_week_rate = convert_percentrate(@avg_session_duration_week, (GaDb.last(14).first(7).pluck(:avg_session_duration_day).reduce(:+) / 7).round(2))  
    @avg_session_duration_month_rate = convert_percentrate(@avg_session_duration_month, (GaDb.last(56).first(28).pluck(:avg_session_duration_day).reduce(:+) / 28).round(2))  
    
    # 官網使用者年齡分佈
    @user_age_bracket_month = ga_preprocess(GaDb.last(28).pluck(:user_18_24), GaDb.last(28).pluck(:user_25_34), GaDb.last(28).pluck(:user_35_44), GaDb.last(28).pluck(:user_45_54), GaDb.last(28).pluck(:user_55_64), GaDb.last(28).pluck(:user_65))
    
    # 官網使用者裝置分析
    @desktop = GaDb.last(28).pluck(:desktop_user).reduce(:+)
    @mobile = GaDb.last(28).pluck(:mobile_user).reduce(:+)
    @tablet = GaDb.last(28).pluck(:tablet_user).reduce(:+)

    # 官網流量來源與跳出率分析
    # 流量數
    @male_user = GaDb.last(28).pluck(:male_user).reduce(:+)
    @female_user = GaDb.last(28).pluck(:female_user).reduce(:+)

    # 跳出率
    @new_visitor = GaDb.last(28).pluck(:new_visitor).reduce(:+)
    @returning_visitor = GaDb.last(28).pluck(:return_visitor).reduce(:+)
  end

  def excel
    last_month_mon

    fb = FbDb.where(date: @last..@end)
    ga = GaDb.where(date: @last..@end)
    mailchimp = MailchimpDb.where(date: @last..@end)

    export_xls = ExportXls.new
    
    export_xls.fb_xls(fb)
    export_xls.ga_xls(ga)
    export_xls.mailchimp_xls(mailchimp)
    export_xls.alexa_xls(AlexaDb.last)
    export_xls.fb_post(@last, @end)
    
    respond_to do |format|
      format.xls { 
        send_data(export_xls.export,
        :type => "text/excel; charset=utf-8; header=present",
        :filename => "社企流#{(Date.today << 1).strftime("%m")[1]}月資料分析.xls")
      }
    end
  end

  def exceldate
    if !params[:starttime].nil?
      excel = ExcelDb.new
      excel.start = params[:starttime]
      excel.before = params[:endtime]
      excel.save!
    else
      @starttime = ExcelDb.last.start.to_date
      @endtime = ExcelDb.last.before.to_date
      m = @endtime - @starttime
      @last = @starttime - (m % 7)

      fb = FbDb.where(date: @last..@endtime)
      ga = GaDb.where(date: @last..@endtime)
      mailchimp = MailchimpDb.where(date: @starttime..@endtime)

      # export to xls
      export_xls = ExportXls.new

      export_xls.fb_xls(fb) unless fb.nil?
      export_xls.ga_xls(ga) unless ga.nil?
      export_xls.mailchimp_xls(mailchimp) unless mailchimp.nil?
      export_xls.alexa_xls(AlexaDb.last)
      export_xls.fb_post(@starttime, @endtime)

      respond_to do |format|
        format.xls { 
          send_data(export_xls.export,
          :type => "text/excel; charset=utf-8; header=present",
          :filename => "#{@starttime}~#{@endtime}社企流資料分析.xls")
        }
      end
    end
  end

  private

  # 轉換成比例((新值-舊值)/舊值)
  def convert_percentrate(datanew, dataold)
    return ((datanew - dataold) / dataold.abs.to_f * 100).round(2)
  end

  # 上個月第一個星期一的日期 往後推七天
  def last_month_mon
    d = Date.today
    d = d << 1
    d = d.to_s
    @last = Date.new(d[0..3].to_i, d[5..6].to_i, 1)
    while @last.strftime("%a") != "Mon"
      @last -= 1
    end
    @end = (@last + 35).strftime("%Y-%m-%d")
    @last = @last.strftime("%Y-%m-%d") # 格式2018-08-18
  end

  def fbinformation
    # 連到fb api

    # 取得最新的粉專讚數
    @fans = FbDb.first.fans
    
    # 粉絲專頁讚數折線圖
    @fans_adds_last_30d = FbDb.last(28).pluck(:fans_adds_day)
    @fans_adds_last_7d = @fans_adds_last_30d.last(7)

    # 粉絲專頁讚數比例
    @fans_adds_week_rate = convert_percentrate(FbDb.last.fans_adds_week, FbDb.last(8).first.fans_adds_week)
    @fans_adds_month_rate = convert_percentrate(FbDb.last.fans_adds_month, FbDb.last(29).first.fans_adds_month)

    # 粉專曝光使用者
    @page_users_week = FbDb.last.page_users_week
    @page_users_month = FbDb.last.page_users_month

    # 粉專曝光使用者折線圖
    @page_users_last_30d = FbDb.last(28).pluck(:page_users_day)
    @page_users_last_7d = @page_users_last_30d.last(7)

    # 粉專曝光使用者比例
    @page_users_week_rate = convert_percentrate(@page_users_week, FbDb.last(8).first.page_users_week) 
    @page_users_month_rate = convert_percentrate(@page_users_month, FbDb.last(29).first.page_users_month)
    
    # 粉絲黏著度分析
    # 貼文觸及人數
    @posts_users_last_7d = FbDb.last(7).pluck(:posts_users_day)
    @posts_users_last_4w = FbDb.last(22).pluck(:posts_users_week).values_at(0, 7, 14, 21)

    # 貼文互動人數
    @enagements_users_last_7d = FbDb.last(7).pluck(:enagements_users_day)
    @enagements_users_last_4w = FbDb.last(22).pluck(:enagements_users_week).values_at(0, 7, 14, 21)

    # 互動率
    @fans_retention_rate_7d = @enagements_users_last_7d.zip(@posts_users_last_7d).map { |x, y| (x / y.to_f).round(2) }
    @fans_retention_rate_30d = @enagements_users_last_4w.zip(@posts_users_last_4w).map { |x, y| (x / y.to_f).round(2) }

    # 日期(fb的日期為到期日的早上七點 所以減一才是那天的值)
    @fb_last_7d_date = FbDb.last(7).pluck(:date).map { |a| (a - 1).strftime("%m%d").to_i }
    @fb_last_4w_date = FbDb.last(22).pluck(:date).map { |a| (a - 1).strftime("%m%d").to_i }.values_at(0, 7, 14, 21)
  end

  def gainformation
    # 官網使用者
    @web_users_week = GaDb.last.web_users_week
    @web_users_month = GaDb.last.web_users_month
   
    # 官網使用者折線圖
    @web_users_last_30d = GaDb.last(28).pluck(:web_users_day)
    @web_users_last_7d = @web_users_last_30d.last(7)
    
    # 官網使用者比例
    @web_users_week_rate = convert_percentrate(@web_users_week, GaDb.last(8).first.web_users_week)  
    @web_users_month_rate = convert_percentrate(@web_users_month, GaDb.last(29).first.web_users_month)
    
    # 所有使用者
    @all_users_views_last_7d_data = GaDb.last(7).pluck(:pageviews_day)
    @all_users_views_last_4w_data = get_week_data(GaDb.last(28).pluck(:pageviews_day))

    # 官網瀏覽活躍度分析
    # 多工作階段使用者(所有使用者-單工作階段使用者)
    @activeusers_views_last_7d_data = @all_users_views_last_7d_data.zip(GaDb.last(7).pluck(:single_session)).map { |k| (k[0] - k[1]) }
    @activeusers_views_last_4w_data = @all_users_views_last_4w_data.zip(get_week_data(GaDb.last(28).pluck(:single_session))).map { |k| (k[0] - k[1]) }
    
    # 活躍度(多工作階段使用者/所有使用者)
    @users_activity_rate_7d = @activeusers_views_last_7d_data.zip(@all_users_views_last_7d_data).map { |k| (k[0] / k[1].to_f).round(2) }
    @users_activity_rate_4w = @activeusers_views_last_4w_data.zip(@all_users_views_last_4w_data).map { |k| (k[0] / k[1].to_f).round(2) }
    
    # 日期
    @ga_last_7d_date = GaDb.last(7).pluck(:date).map { |a| a.strftime("%m%d").to_i }
    @ga_last_4w_date = GaDb.last(22).pluck(:date).map { |a| a.strftime("%m%d").to_i }.values_at(0, 7, 14, 21)
    
    # 官網流量來源與跳出率分析
    # 官網流量來源
    @channel_user_week = ga_preprocess(GaDb.last(7).pluck(:oganic_search_day), GaDb.last(7).pluck(:social_user_day), GaDb.last(7).pluck(:direct_user_day), GaDb.last(7).pluck(:referral_user_day), GaDb.last(7).pluck(:email_user_day))
    @channel_user_month = ga_preprocess(GaDb.last(28).pluck(:oganic_search_day), GaDb.last(28).pluck(:social_user_day), GaDb.last(28).pluck(:direct_user_day), GaDb.last(28).pluck(:referral_user_day), GaDb.last(28).pluck(:email_user_day))
    
    # 官網流量來源跳出率
    @bounce_rate_week = ga_preprocess_rate(GaDb.last(7).pluck(:oganic_search_bounce), GaDb.last(7).pluck(:social_bounce), GaDb.last(7).pluck(:direct_bounce), GaDb.last(7).pluck(:referral_bounce), GaDb.last(7).pluck(:email_bounce))
    @bounce_rate_month = ga_preprocess_rate(GaDb.last(28).pluck(:oganic_search_bounce), GaDb.last(28).pluck(:social_bounce), GaDb.last(28).pluck(:direct_bounce), GaDb.last(28).pluck(:referral_bounce), GaDb.last(28).pluck(:email_bounce))
  end

  # 拿到每周的加總值
  def get_week_data(data, week_cnt = 4)
    data[0, week_cnt * 7].each_slice(7).map{ |arr| arr.reduce(:+) }
  end

  # channel裡的值去掉nil把值相加
  def ga_preprocess(data1, data2, data3, data4, data5, data6 = nil)
    value = []
    value << data1.compact.reduce(:+).round(2)
    value << data2.compact.reduce(:+).round(2)
    value << data3.compact.reduce(:+).round(2)
    value << data4.compact.reduce(:+).round(2)
    value << data5.compact.reduce(:+).round(2)
    value << data6.compact.reduce(:+).round(2) unless data6.nil?
    return value
  end

  # channel裡的值去掉nil把值相加取平均
  def ga_preprocess_rate(data1, data2, data3, data4, data5)
    value = []
    value << data1.compact.reduce(:+) / data1.compact.size
    value << data2.compact.reduce(:+) / data2.compact.size
    value << data3.compact.reduce(:+) / data3.compact.size
    value << data4.compact.reduce(:+) / data4.compact.size
    value << data5.compact.reduce(:+) / data5.compact.size
  end
  
end
