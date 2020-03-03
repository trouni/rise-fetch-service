# frozen_string_literal: true

# require 'open-uri'
require 'rest-client'
require 'json'
require 'date'

class InstagramAPI
  def self.fetch_user_info(username, id = nil)
    puts "Fetching information for Instagramer user: #{username}"
    begin
      response = RestClient.get("https://www.instagram.com/#{username}/?__a=1")
      user_hash = JSON.parse(response.body)['graphql']['user']

      attributes = {
        needs_update: false,
        info_fetched_at: DateTime.now,
        instagram_id: user_hash['id'],
        biography: user_hash['biography'],
        username: user_hash['username'],
        full_name: user_hash['full_name'],
        profile_pic_url: user_hash['profile_pic_url'],
        followers: user_hash['edge_followed_by']['count'],
        following: user_hash['edge_follow']['count'],
        is_private: user_hash['is_private'],
        is_verified: user_hash['is_verified'],
        is_ja: ja?([user_hash['full_name'], user_hash['biography']]),
        country_block: user_hash['country_block'],
        has_channel: user_hash['has_channel'],
        highlight_reel_count: user_hash['highlight_reel_count'],
        is_business_account: user_hash['is_business_account'],
        business_category_name: user_hash['business_category_name'],
        is_joined_recently: user_hash['is_joined_recently'],
        connected_fb_page: user_hash['connected_fb_page'],
        posts_count: user_hash['edge_owner_to_timeline_media']['count'],
        posts_30_days: count_posts(user_hash) { |posts| posts.select { |post| post[:datetime] > DateTime.now - 30 } },
        avg_likes_last_3: avg_engagement(user_hash, :likes_count) { |posts| posts.last(3) },
        avg_likes_last_10: avg_engagement(user_hash, :likes_count) { |posts| posts.last(10) },
        avg_likes_30_days: avg_engagement(user_hash, :likes_count) { |posts| posts.select { |post| post[:datetime] > DateTime.now - 30 } },
        avg_comments_last_3: avg_engagement(user_hash, :comments_count) { |posts| posts.last(3) },
        avg_comments_last_10: avg_engagement(user_hash, :comments_count) { |posts| posts.last(10) },
        avg_comments_30_days: avg_engagement(user_hash, :comments_count) { |posts| posts.select { |post| post[:datetime] > DateTime.now - 30 } }
      }
    rescue StandardError => error
      puts error
      puts "NOT FOUND: User #{username} may have updated their username or deleted their account."
      attributes = { username: username, needs_update: true, info_fetched_at: DateTime.now }
    end
    attributes = attributes.merge(id: id) if id
    attributes
  end

  class << self
    private

    def ja?(strings)
      strings.each do |string|
        ja_regex = /[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\uff00-\uff9f\u4e00-\u9faf\u3400-\u4dbf]/
        return true if ja_regex.match(string)
      end
      false
    end

    def format_posts(user_hash)
      posts = user_hash['edge_owner_to_timeline_media']['edges'].map do |media|
        {
          id: media['node']['id'],
          shortcode: media['node']['shortcode'],
          caption: media['node']['edge_media_to_comment']['count'],
          comments_count: media['node']['edge_media_to_comment']['count'],
          likes_count: media['node']['edge_liked_by']['count'],
          is_video: media['node']['is_video'],
          datetime: DateTime.strptime(media['node']['taken_at_timestamp'].to_s, '%s')
        }
      end
      posts.sort_by { |post| post[:datetime] }
    end

    def avg_engagement(user_hash, column = :likes_count)
      posts = format_posts(user_hash)
      selection = block_given? ? yield(posts) : posts
      return nil unless selection.any?

      result = selection.sum { |post| post[column] } / selection.count.to_f
      result.round(1)
    end

    def count_posts(user_hash)
      posts = format_posts(user_hash)
      selection = block_given? ? yield(posts) : posts
      selection.count
    end
  end
end
