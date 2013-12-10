require 'test_helper'
require 'pry'

class Publisher
  include Elasticsearch::Model::Persistence

  property :name,     String, analyzer: 'snowball'
  property :location, [Float], type: 'geo_point', default: []
end

class Item
  include Virtus.model
  attribute :name, String
end

class Meta
  include Virtus.model
  attribute :views, Integer, default: 0
end

class Article
  include Elasticsearch::Model::Persistence

  settings index: { number_of_shards: 1 }

  validates_presence_of :name

  property :name,       String,    analyzer: 'snowball'
  property :publisher,  Publisher, default: Publisher.new
  property :meta,       Meta
  property :blank,      Boolean,   default: true
  property :tags,       [String],  index: 'not_analyzed', default: []
  property :items,      [Item],    index: 'not_analyzed', default: []
  property :downloads,  Integer,   default: 0
  property :views,      Integer,   default: 0, type: 'long'
  property :created_at, Time,      default: lambda { |article, attribute| Time.now.utc }
end

class ActiveModelLint < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  def setup
    super
    @model = Article.new name: 'Test'
  end
end

class ElasticsearchModelPersistenceTest < Test::Unit::TestCase

  context "When defining model properties" do

    should "be set with Hash of attributes" do
      assert_nothing_raised { Article.new name: 'Test' }
    end

    should "set only defined attributes" do
      assert_raise(NoMethodError) do
        article = Article.new foo: 'bar', name: 'Test'
        assert_equal 'Test', article.name
        article.foo
      end
    end

    should "set properties" do
      article = Article.new name: 'Test', meta: { views: 1000 }, items: [ {name: 'one'}, {name: 'two'} ], tags: ['A', 'B']
      assert_equal 'Test', article.name
      assert_equal 1000,   article.meta.views
      assert_equal 'one',  article.items.first.name
      assert_equal 'A',    article.tags.first
    end

    should "be not persisted by default" do
      assert ! Article.new.persisted?
    end

    should "be serializable to JSON" do
      article = Article.new name: 'Test', meta: { views: 1000 }
      assert_equal Hash, article.as_json.class
      assert_equal String, article.to_json.class
      assert_equal 'Test', MultiJson.decode(article.to_json)['name']
    end

    should "be able to define custom class as type" do
      article = Article.new meta: { views: 1000 }
      assert_kind_of Meta, article.meta
      assert_equal 1000,   article.meta.views
    end

  end

  context "When defining model mapping" do

    should "detect mapping type from defined by properties" do
      assert_equal 'string',  Article.mappings.to_hash[:article][:properties][:name][:type]
      assert_equal 'object',  Article.mappings.to_hash[:article][:properties][:meta][:type]
      assert_equal 'boolean', Article.mappings.to_hash[:article][:properties][:blank][:type]
      assert_equal 'string',  Article.mappings.to_hash[:article][:properties][:tags][:type]
      assert_equal 'object',  Article.mappings.to_hash[:article][:properties][:items][:type]
      assert_equal 'integer', Article.mappings.to_hash[:article][:properties][:downloads][:type]
      assert_equal 'date',    Article.mappings.to_hash[:article][:properties][:created_at][:type]
    end

    should "pass non-virtus options as elasticsearch options" do
      assert_equal 'snowball',     Article.mappings.to_hash[:article][:properties][:name][:analyzer]
      assert_equal 'not_analyzed', Article.mappings.to_hash[:article][:properties][:items][:index]
    end

    should "be able to overwrite detected type" do
      assert_equal 'long',  Article.mappings.to_hash[:article][:properties][:views][:type]
    end

    should "get mapping from nested model" do
      mappings = Article.mappings.to_hash

      assert_equal( {analyzer: "snowball", type: "string"}, mappings[:article][:properties][:publisher][:properties][:name] )
      assert_equal( {type: 'geo_point'}, mappings[:article][:properties][:publisher][:properties][:location] )
    end

  end

  context "Model defaults" do

    should "be able to set" do
      article = Article.new
      assert_equal 0, article.downloads
      assert_equal [], article.items
      assert_kind_of Time, article.created_at

      assert_kind_of Publisher, article.publisher
      assert_equal [], article.publisher.location
    end

  end

  context "Instance" do

    setup do
      @article = Article.new name: 'Test'
    end

    should "have as_json method" do
      @article.set_id '123'

      assert_equal 'Test', @article.as_json["name"]
      assert_equal '123',  @article.as_json["id"]
    end

    should "return hash without `id` property when as_indexed_json method is called" do
      @article.set_id '123'

      assert_equal 'Test', @article.as_indexed_json["name"]
      assert_nil @article.as_indexed_json["id"]
    end

  end

  context "When persisting" do

    setup do
      @article             = Article.new name: 'Test' 
      @elasticsearch_proxy = stub
    end

    should "be persisted" do
      @elasticsearch_proxy.expects(:index_document).returns("_id" => 123, "_version" => 1, "ok" => true)
      @article.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

      assert ! @article.persisted?

      @article.save

      assert @article.persisted?

      assert_equal 1, @article.version
      assert_equal 123, @article.id
    end

    should "be updated" do
      @article.persisted = true

      @elasticsearch_proxy.expects(:update_document).returns("_version" => 5)
      @article.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

      @article.save

      assert_equal 5, @article.version
    end

    should "remove document" do
      @article = Article.new name: 'Test' 

      @elasticsearch_proxy.expects(:delete_document).returns({})
      @article.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)
      @article.expects(:freeze)

      @article.destroy

      assert ! @article.persisted?
      assert @article.destroyed?
    end

    should "be able to create document" do
      @elasticsearch_proxy.expects(:index_document).returns("_id" => 123, "_version" => 1, "ok" => true)
      Article.any_instance.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

      article = Article.create(name: 'Test')

      assert_equal 123, article.id
      assert_equal 1,   article.version
      assert article.persisted?
    end

    should "not persist invalid document" do
      @elasticsearch_proxy.expects(:index_document).never
      Article.any_instance.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

      article = Article.new

      assert ! article.save
      assert ! Article.create(blank: false)
    end

  end

end
