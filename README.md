# mysql2-cs-bind

'mysql2-cs-bind' is extension of 'mysql2', to add method of client-side variable binding (pseudo prepared statement).

## Installation

Add this line to your application's Gemfile:

    gem 'mysql2-cs-bind'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mysql2-cs-bind

## Usage

Require 'mysql2-cs-bind' instead of (or after) 'mysql2', you can use Mysql2::Client#xquery with bound variables like below:

    require 'mysql2-cs-bind'
    client = Mysql2::Client.new(...)
    client.xquery('SELECT x,y,z FROM tbl WHERE x=? AND y=?', val1, val2) #=> Mysql2::Result

Mysql2::Client#xquery receives query, variables, and options(hash) for Mysql2::Client#query.

    client.xquery(sql)
    client.xquery(sql, :as => :array)
    client.xquery(sql, val1, val2)
    client.xquery(sql, [val1, val2])
    client.xquery(sql, val1, val2, :as => :array)
    client.xquery(sql, [val1, val2], :as => :array)
    
Mysql2::Client#xquery raises ArgumentError if mismatch found between placeholder number and arguments

    client.xquery('SELECT x FROM tbl', 1)                   # ArgumentError
    client.xquery('SELECT x FROM tbl WHERE x=? AND y=?', 1) # ArgumentError
    client.xquery('SELECT x FROM tbl WHERE x=?', 1, 2)      # ArgumentError

Formatting for nil and Time objects:

    client.xquery('INSERT INTO tbl (val1,created_at) VALUES (?,?)', nil, Time.now)
    #execute "INSERT INTO tbl (val1,created_at) VALUES (NULL,'2012-01-02 13:45:01')"

Expanding for Array object.

    client.xquery('SELECT val1 FROM tbl WHERE id IN (?)', [[1,2,3]])
    #execute "SELECT val1 FROM tbl WHERE id IN ('1','2','3')"

### Type Conversion of Numbers

Mysql2::Client#xquery quotes any values as STRING. This may not be problems for almost all kind of queries, but sometimes you may be confused by return value types:

    client.query('SELECT 1', :as => :array).first #=> [1]
    client.xquery('SELECT ?', 1, :as => :array).first #=> ['1']

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)

## License
MIT (see MIT-LICENSE)
