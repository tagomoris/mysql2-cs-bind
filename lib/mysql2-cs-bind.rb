# frozen_string_literal: true

require 'mysql2'

class Mysql2::Client

  def xquery(sql, *args, **options)
    if args.empty?
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

    if placeholders.length != values.length &&
       placeholders.length != (values = values.flatten(1)).length
      raise ArgumentError, "mismatch between placeholders number and values arguments"
    end

    while pos = placeholders.pop()
      rawvalue = values.pop()
      if rawvalue.is_a?(Array)
        sql[pos] = rawvalue.map{|v| quote(v) }.join(",")
      else
        sql[pos] = quote(rawvalue)
      end
    end
    sql
  end

  private

  def self.quote(rawvalue)
    case rawvalue
    when nil
      'NULL'
    when true
      'TRUE'
    when false
      'FALSE'
    else
      if rawvalue.respond_to?(:strftime)
        "'#{rawvalue.strftime('%Y-%m-%d %H:%M:%S')}'"
      else
        "'#{Mysql2::Client.escape(rawvalue.to_s)}'"
      end
    end
  end
end
