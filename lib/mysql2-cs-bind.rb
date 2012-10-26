require 'mysql2'

class Mysql2::Client

  def xquery(sql, *args)
    options = if args.size > 0 and args[-1].is_a?(Hash)
                args.pop
              else
                {}
              end
    if args.size < 1
      query(sql, options)
    else
      query(Mysql2::Client.pseudo_bind(sql, args), options)
    end
  end

  def self.pseudo_bind(sql, values)
    sql = sql.dup

    placeholders = []
    search_pos = 0
    while pos = sql.index('?', search_pos)
      placeholders.push(pos)
      search_pos = pos + 1
    end
    values = values.flatten(1) if placeholders.length == values.flatten(1).length
    raise ArgumentError, "mismatch between placeholders number and values arguments" if placeholders.length != values.length

    while pos = placeholders.pop()
      rawvalue = values.pop()
      if rawvalue.nil?
        sql[pos] = 'NULL'
      elsif rawvalue.respond_to?(:strftime)
        sql[pos] = "'" + rawvalue.strftime('%Y-%m-%d %H:%M:%S') + "'"
      elsif rawvalue.is_a?(Array)
        sql[pos] = rawvalue.map{|v| "'" + Mysql2::Client.escape(v.to_s) + "'" }.join(",")
      else
        sql[pos] = "'" + Mysql2::Client.escape(rawvalue.to_s) + "'"
      end
    end
    sql
  end

end
