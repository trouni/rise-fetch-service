# frozen_string_literal: true

require 'rest-client'
require 'json'

class RiseAPI
  RISE_API_URL = "https://instaxxeum.herokuapp.com/graphql"
  UPDATE_INSTAGRAMER_QUERY = <<-'GRAPHQL'
    mutation updateInstagramer
    (
        $id: ID,
        $needsUpdate: Boolean,
        $instagramId: String,
        $biography: String,
        $username: String,
        $fullName: String,
        $profilePicUrl: String,
        $followers: Int,
        $following: Int,
        $isPrivate: Boolean,
        $isVerified: Boolean,
        $isJa: Boolean,
        $countryBlock: Boolean,
        $hasChannel: Boolean,
        $highlightReelCount: Int,
        $isBusinessAccount: Boolean,
        $businessCategoryName: String,
        $isJoinedRecently: Boolean,
        $connectedFbPage: Boolean,
        $postsCount: Int,
        $posts30Days: Int,
        $avgLikesLast3: Float,
        $avgLikesLast10: Float,
        $avgLikes30Days: Float,
        $avgCommentsLast3: Float,
        $avgCommentsLast10: Float,
        $avgComments30Days: Float
    )
    {
        updateInstagramer
        (
            input:
            {
                id: $id,
                needsUpdate: $needsUpdate,
                instagramId: $instagramId,
                biography: $biography,
                username: $username,
                fullName: $fullName,
                profilePicUrl: $profilePicUrl,
                followers: $followers,
                following: $following,
                isPrivate: $isPrivate,
                isVerified: $isVerified,
                isJa: $isJa,
                countryBlock: $countryBlock,
                hasChannel: $hasChannel,
                highlightReelCount: $highlightReelCount,
                isBusinessAccount: $isBusinessAccount,
                businessCategoryName: $businessCategoryName,
                isJoinedRecently: $isJoinedRecently,
                connectedFbPage: $connectedFbPage,
                postsCount: $postsCount,
                posts30Days: $posts30Days,
                avgLikesLast3: $avgLikesLast3,
                avgLikesLast10: $avgLikesLast10,
                avgLikes30Days: $avgLikes30Days,
                avgCommentsLast3: $avgCommentsLast3,
                avgCommentsLast10: $avgCommentsLast10,
                avgComments30Days: $avgComments30Days
            }
        )
        {
            errors
            ok
        }
    }
  GRAPHQL

  def self.fetch_user(username)
    attributes = InstagramAPI.fetch_user_info(username)
    response = post_instagramer(attributes)
    result = JSON.parse(response)
    return 'No body in response.' unless result

    if result
      result = result['data']['updateInstagramer']
      ok = result['ok']
      {
        ok: ok,
        username: username,
        message: ok ? 'Successfully fetched info.' : result['errors'].join(' ')
      }
    end
  end

  def self.post_instagramer(attributes)
    payload = {
      query: UPDATE_INSTAGRAMER_QUERY,
      variables: camelize_hash(attributes)
    }
    headers = { content_type: :json, accept: :json }
    return RestClient.post(RISE_API_URL, payload.to_json, headers)
  end

  def self.camelize_hash(variables)
    result = {}
    variables.each { |k, v| result[lower_camelize(k)] = v }
    result
  end

  def self.lower_camelize(str)
    str.to_s.split('_').map.with_index { |word, index| index.zero? ? word : word.capitalize }.join
  end
end
