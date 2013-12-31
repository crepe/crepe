# Crêpe [![Build Status][1]][2] [![Code Climate][3]][4]

The thin API stack.

[1]: https://travis-ci.org/stephencelis/crepe.png
[2]: https://travis-ci.org/stephencelis/crepe
[3]: https://codeclimate.com/github/stephencelis/crepe.png
[4]: https://codeclimate.com/github/stephencelis/crepe

## Example

``` ruby
# config.ru
require 'crepe'
require 'twitter_api/v1'

class TwitterAPI < Crepe::API
  extend Crepe::Streaming

  version '1.1' do
    let!(:current_user)       { User.authorize!(*request.credentials) }

    namespace :statuses do
      # helpers
      let(:tweet_params)      {
        params.require(:status).permit :message, :in_reply_to_status_id
      }
      let(:current_tweet)     { current_user.tweets.find params[:id] }

      # endpoints
      get(:home_timeline)     { current_user.timeline }
      get(:mentions_timeline) { current_user.mentions }
      get(:user_timeline)     { current_user.tweets }
      get(:retweets_of_me)    { current_user.tweets.retweeted }

      post(:update)           { current_user.tweets.create! tweet_params }
      get('show/:id')         { current_tweet }
      get('retweets/:id')     { current_tweet.retweets }
      post('destroy/:id')     { current_tweet.destroy }
      post('retweet/:id')     { current_user.retweet! Tweet.find params[:id] }

      stream(:firehose)       { Tweet.stream { |t| render t } }
      stream(:sample)         { Tweet.sample.stream { |t| render t } }
    end

    get('search/tweets')      { Tweet.search params.slice Tweet::SEARCH_KEYS }
    stream(:user)             { current_user.timeline.stream { |t| render t } }
  end

  mount TwitterAPI::V1

  rescue_from ActiveRecord::RecordNotFound do |e|
    error! :not_found, e.message
  end
  rescue_from ActiveRecord::InvalidRecord do |e|
    error! :unprocessable_entity, e.message, errors: e.record.errors
  end
  rescue_from User::Unauthorized do |e|
    unauthorized! realm: 'Twitter API'
  end
end

run TwitterAPI
```

## License

(The MIT License.)

© 2013 Stephen Celis <stephen@stephencelis.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
