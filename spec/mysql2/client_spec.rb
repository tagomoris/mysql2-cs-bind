# encoding: UTF-8
require 'spec_helper'
require 'time'

describe Mysql2::Client do
  before(:each) do
    @client = Mysql2::Client.new
    @klass = Mysql2::Client
  end

  it "should respond to #query" do
    @client.should respond_to(:query)
  end

  context "#pseudo_bind" do
    it "should return query just same as argument, if without any placeholders" do
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x='1'", []).should eql("SELECT x,y,z FROM x WHERE x='1'")
    end

    it "should return replaced query if with placeholders" do
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x=?", [1]).should eql("SELECT x,y,z FROM x WHERE x='1'")
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x=? AND y=?", [1, 'X']).should eql("SELECT x,y,z FROM x WHERE x='1' AND y='X'")
    end
      
    it "should raise ArgumentError if mismatch exists between placeholders and arguments" do
      expect {
        @klass.pseudo_bind("SELECT x,y,z FROM x", [1])
      }.should raise_exception(ArgumentError)
      expect {
        @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x=?", [1,2])
      }.should raise_exception(ArgumentError)
      expect {
        @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x=? AND y=?", [1])
      }.should raise_exception(ArgumentError)
      expect {
        @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x=?", [])
      }.should raise_exception(ArgumentError)
    end

    it "should replace placeholder with NULL about nil" do
      @klass.pseudo_bind("UPDATE x SET y=? WHERE x=?", [nil,1]).should eql("UPDATE x SET y=NULL WHERE x='1'")
    end

    it "should replace placeholder with formatted timestamp string about Time object" do
      t = Time.strptime('2012/04/20 16:50:45', '%Y/%m/%d %H:%M:%S')
      @klass.pseudo_bind("UPDATE x SET y=? WHERE x=?", [t,1]).should eql("UPDATE x SET y='2012-04-20 16:50:45' WHERE x='1'")
    end

    it "should replace placeholder with TRUE/FALSE about true/false" do
      @klass.pseudo_bind("UPDATE x SET y=? WHERE x=?", [true,1]).should eql("UPDATE x SET y=TRUE WHERE x='1'")
      @klass.pseudo_bind("UPDATE x SET y=? WHERE x=?", [false,1]).should eql("UPDATE x SET y=FALSE WHERE x='1'")
    end

    it "should replace placeholder with value list about Array object" do
      t = Time.strptime('2012/04/20 16:50:45', '%Y/%m/%d %H:%M:%S')
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x in (?)", [[1,2,3]]).should eql("SELECT x,y,z FROM x WHERE x in ('1','2','3')")
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x = ? and y in (?)", [1, [1, 2, 3]]).should eql("SELECT x,y,z FROM x WHERE x = '1' and y in ('1','2','3')")
      @klass.pseudo_bind("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id in (?)", [1, [2,3]]).should eql("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = '1' OR id in ('2','3')")
      @klass.pseudo_bind("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?) OR id = ?", [[1,2], 3]).should eql("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in ('1','2') OR id = '3'")
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x = ? and y in (?)", [1, [true, nil]]).should eql("SELECT x,y,z FROM x WHERE x = '1' and y in (TRUE,NULL)")
      @klass.pseudo_bind("SELECT x,y,z FROM x WHERE x = ? and y in (?)", [1, [t, nil]]).should eql("SELECT x,y,z FROM x WHERE x = '1' and y in ('2012-04-20 16:50:45',NULL)")
    end
  end

  context "#xquery" do
    it "should let you query again if iterating is finished when streaming" do
      @client.xquery("SELECT 1 UNION SELECT ?", 2, :stream => true, :cache_rows => false).each {}

      expect {
        @client.xquery("SELECT 1 UNION SELECT ?", 2, :stream => true, :cache_rows => false)
      }.to_not raise_exception(Mysql2::Error)
    end

    it "should accept an options hash that inherits from Mysql2::Client.default_query_options" do
      @client.xquery "SELECT ?", 1, :something => :else
      @client.query_options.should eql(@client.query_options.merge(:something => :else))
    end

    it "should return results as a hash by default" do
      @client.xquery("SELECT ?", 1).first.class.should eql(Hash)
    end

    it "should be able to return results as an array" do
      @client.xquery("SELECT ?", 1, :as => :array).first.class.should eql(Array)
      @client.xquery("SELECT ?", 1).each(:as => :array)
      @client.query("SELECT 1").first.should eql([1])
      @client.query("SELECT '1'").first.should eql(['1'])
      @client.xquery("SELECT 1", :as => :array).first.should eql([1])
      @client.xquery("SELECT ?", 1).first.should eql(['1'])
      @client.xquery("SELECT ?+1", 1).first.should eql([2.0])
    end

    it "should read multi style args" do
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id IN (1)").first["id"].should eql(1)

      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ?", 1).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id = ?", 1, 2).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id = ?", [1,2]).first["id"].should eql(1)

      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?)", [1,2,3]).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id in (?)", 1, [2,3]).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id in (?)", [1, [2,3]]).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?) OR id = ?", [1,2], 3).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?) OR id = ?", [[1,2], 3]).first["id"].should eql(1)

      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id IN (1)",:something => :else).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id = ? OR id in (?)", 1, [2,3],:something => :else).first["id"].should eql(1)
      @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?) OR id = ?", [[1,2], 3],:something => :else).first["id"].should eql(1)

      expect {
        @client.xquery("SELECT id FROM (SELECT 1 AS id) AS tbl WHERE id in (?) OR id = ?", [[1,2], 3, 4],:something => :else)
      }.should raise_exception(ArgumentError)
    end

    it "should be able to return results with symbolized keys" do
      @client.xquery("SELECT 1", :symbolize_keys => true).first.keys[0].class.should eql(Symbol)
    end

    it "should require an open connection" do
      @client.close
      lambda {
        @client.xquery "SELECT ?", 1
      }.should raise_error(Mysql2::Error)
    end
  end

  it "should respond to escape" do
    Mysql2::Client.should respond_to(:escape)
  end

  if RUBY_VERSION =~ /1.9/
    it "should respond to #encoding" do
      @client.should respond_to(:encoding)
    end
  end
end
