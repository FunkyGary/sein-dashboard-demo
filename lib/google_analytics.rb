require 'google/apis/analyticsreporting_v4'
require "googleauth"

class GoogleAnalytics

  include Google::Apis::AnalyticsreportingV4

  mattr_accessor :credentials
  mattr_accessor :analytics

  def initialize(since, before)
    self.credentials = 
      Google::Auth::UserRefreshCredentials.new(
      scope: ["https://www.googleapis.com/auth/analytics.readonly"],
      additional_parameters: { "access_type" => "offline" }
    )

    self.analytics = AnalyticsReportingService.new
    analytics.authorization = credentials
    @since = since
    @before = before
  end

  def users
    request_simple("ga:users", "ga:date")
  end

  def users_7
    request_simple("ga:7dayUsers", "ga:date")
  end

  def users_30
    request_simple("ga:30dayUsers", "ga:date")
  end

  def bounce
    request_simple("ga:bounceRate", "ga:date")
  end

  def pageview
    request_simple("ga:pageviews", "ga:date")
  end

  def session
    request_simple("ga:sessions", "ga:date")
  end

  def user_type
    request_two_dim("ga:users", "ga:userType")
  end

  def user_type_week
    request_simple("ga:users", "ga:userType")
  end

  def channel(token = 0)
    request_two("ga:sessions", "ga:bounceRate", "ga:channelGrouping", token)
  end

  def avg_session
    request_simple("ga:avgSessionDuration", "ga:date")
  end

  def avg_session_week
    request_total_simple("ga:avgSessionDuration")
  end

  def avg_time_page
    request_simple("ga:avgTimeOnPage", "ga:date")
  end

  def avg_time_page_week
    request_total_simple("ga:avgTimeOnPage")
  end

  def bracket(token = 0)
    request_two_dim("ga:users", "ga:userAgeBracket", token)
  end

  def bracket_week
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: "ga:users"
          }
        ], dimensions: [
          {
            name: "ga:userAgeBracket"
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ]
      }] }
    )
    response = analytics.batch_get_reports(request)
    JSON.parse(response.to_json)["reports"][0]["data"]
  end

  def gender(token = 0)
    request_two_dim("ga:users", "ga:userGender", token)
  end

  def gender_week
    request_simple("ga:users", "ga:userGender")
  end

  def page_per_session
    request_simple("ga:pageviewsPerSession", "ga:date")
  end

  def page_per_session_week
    request_total_simple("ga:pageviewsPerSession")
  end

  def device(token = 0)
    request_two_dim("ga:users", "ga:deviceCategory", token)
  end

  def session_pageviews
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: "ga:pageviews"
          }
        ], dimensions: [
          {
            name: "ga:sessionCount"
          }, {
            name: "ga:date"
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ]
      }] }
    )
    return convert(request)
  end

  private

  def request_simple(metrics, dim, token = 0)
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: metrics
          }
        ], dimensions: [
          {
            name: dim
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ], page_token: token.to_s
      }] }
    )
    return convert(request)
  end

  def request_total_simple(metrics, token = 0)
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: metrics
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ], page_token: token.to_s
      }] }
    )
    return convert(request)
  end

  def request_two_dim(metrics, dimensions, token = 0)
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: metrics
          }
        ], dimensions: [
          {
            name: "ga:date"
          }, {
            name: dimensions
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ], page_token: token.to_s
      }] }
    )
    return convert(request)
  end

  def request_two(metrics1, metrics2, dimensions, token = 0)
    request = GetReportsRequest.new(
      { report_requests: [{
        view_id: "ga:55621750",
        metrics: [
          {
            expression: metrics1
          }, {
            expression: metrics2
          }
        ], dimensions: [
          {
            name: "ga:date"
          }, {
            name: dimensions
          }
        ], date_ranges: [
          {
            start_date: @since,
            end_date: @before
          }
        ], page_token: token.to_s
      }] }
    )
    return convert(request)
  end

  def convert(request)
    response = analytics.batch_get_reports(request)
    JSON.parse(response.to_json)["reports"][0]["data"]["rows"]
  end

end
