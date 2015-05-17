# Crepe [![Build Status][1]][2] [![Code Climate][3]][4]

Crepe is a lightweight API framework designed to help you write clean, fast web services in Ruby. With an elegant and intuitive DSL inspired by RSpec, and with a nod to Grape, Crepe makes API design simple.

[1]: https://img.shields.io/travis/crepe/crepe.svg?style=flat
[2]: https://travis-ci.org/crepe/crepe
[3]: https://img.shields.io/codeclimate/github/crepe/crepe.svg?style=flat
[4]: https://codeclimate.com/github/crepe/crepe

## Installation

In your application's Gemfile:

```ruby
gem 'crepe', github: 'crepe/crepe'
```

If you're coming from Rails and/or you want a Crepe application with a thought-out file structure, you can use [creperie][creperie] to generate a new API:

```bash
$ gem install creperie
$ crepe new my_api
```

[creperie]: https://github.com/crepe/creperie

## Usage

Crepe APIs are, at their core, Rack applications. They can be created by subclassing `Crepe::API`. To detail Crepe's major features, we'll show how [GitHub's Gist API][gist-api] could be written using Crepe:

[gist-api]: https://developer.github.com/v3/gists/

```ruby
# config.ru
require 'bundler/setup'
require 'crepe'

module Gist
  class API < Crepe::API
    # Like `let` in RSpec, this defines a lazy-loading helper.
    let(:current_user) { User.authorize!(request.headers['Authorization']) }

    namespace :gists do
      let(:gist_params) { params.slice(:files, :description, :public) }

      get do
        begin
          current_user.gists.limit(30)
        rescue User::Unauthorized
          Gist.limit(30)
        end
      end

      post { Gist.create(gist_params) }

      get(:public) { Gist.limit(30) }

      get(:starred) { current_user.starred_gists }

      # Specify a parameter as part of the namespace: /gists/:id/...
      param :id do
        let(:gist) { Gist.find(params[:id]) }

        get    { gist }
        put    { gist.update_attributes(gist_params) }
        patch  { gist.update_attributes(gist_params) }
        delete do
          if gist.user == current_user
            gist.destroy and head :no_content
          else
            error! :unauthorized
          end
        end

        # Specify a parameter constraint, e.g. a 40-character hex string
        param(sha: /\h{40}/) { gist.revisions.find(params[:sha]) }
        get(:commits) { gist.commits.limit(30) }

        get :star do
          current_user.starred?(gist)
            head :no_content
          else
            head :not_found
          end
        end
        put(:star)    { current_user.star(gist) }
        delete(:star) { current_user.unstar(gist) }

        get(:forks)  { gist.forks.limit(30) }
        post(:forks) { current_user.fork(gist) }
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      error! :not_found, e.message
    end

    rescue_from ActiveRecord::InvalidRecord do |e|
      error! :unprocessable_entity, e.message, errors: e.record.errors
    end

    rescue_from User::Unauthorized do |e|
      unauthorized! realm: 'Gist API'
    end
  end
end

run Gist::API
```

The above example will give you a Rack application that you can run with the `rackup` command, responding to the following routes:

```
GET    /gists
POST   /gists
GET    /gists/public
GET    /gists/starred
GET    /gists/:id
PUT    /gists/:id
PATCH  /gists/:id
DELETE /gists/:id
GET    /gists/:id/:sha
GET    /gists/:id/commits
GET    /gists/:id/star
PUT    /gists/:id/star
DELETE /gists/:id/star
GET    /gists/:id/forks
POST   /gists/:id/forks
```

## Advanced usage

The above example only skims the surface of what Crepe can do. For more information, see the [Crepe wiki][wiki].

[wiki]: https://github.com/crepe/crepe/wiki

## License

(The MIT License.)

© 2013–2015 Stephen Celis <stephen@stephencelis.com>, Evan Owen <kainosnoema@gmail.com>, David Celis <me@davidcel.is>

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
