require "test/unit"
ENV['TM_GTD_CONTEXT'] = "hello there"
ENV['TM_GTD_CONTEXTS'] = "hello there"
# dump_object reads the editor's indentation settings from the environment
# (TextMate sets these for commands); the fixtures are authored with soft
# tabs at width 2, so pin them for a deterministic round-trip.
ENV['TM_SOFT_TABS'] = "YES"
ENV['TM_TAB_SIZE'] = "2"
ENV['TM_GTD_DIRECTORY'] = __dir__
require_relative "../lib/GTD"
include GTD
class TestGTD < Test::Unit::TestCase
  def setup
    GTDContexts.contexts = nil
  end
  def test_action
    assert_equal(["hello","there"], GTDContexts.contexts)
    @a = Action.new(:name => "the name", :context => "thecontext", :parent => "project", :file => "2005-03-05")
    assert_not_nil(@a)
    assert_equal("the name", @a.name)
    assert_equal("thecontext", @a.context)
    assert_equal("project", @a.parent)
    @b = Action.new(:name => "another action",:context => "emailing",:file => "file2", :line => 15)
    assert_equal("another action", @b.name)
    assert_equal("emailing", @b.context)
    assert_equal(nil, @b.project)
    assert_equal(["file2",15], [@b.file,@b.line])
    assert_equal(nil,@b.due)
    assert_equal(["hello", "there"],GTDContexts.contexts)
  end
  def test_GTD_parse
    assert_equal(["hello","there"],GTDContexts.contexts)
    File.open("#{__dir__}/test_example.gtd") do |f|
      @data = f.read
    end
    instructions = GTD::parse(@data)
    assert_not_nil(instructions)
    assert_equal(11, instructions.length)
    assert_equal([:project,:completed,:action,:action,:project,:action,:end,:action,:end,:action,:note],instructions.map{|i| i[0]}[0..10])
    assert_equal([:project,"World domination",nil,nil], instructions[0])
    assert_equal([:action,"Create giant laser beam [1]","errand","due:[2006-06-04]"], instructions[2])
    assert_equal([:end,nil,nil,nil], instructions[6])
    assert_equal([:action,"Hello there","email",nil], instructions[9])
  end
  def test_GTDFile_initialize
    @object = GTDFile.new("#{__dir__}/test_example.gtd")
    assert_not_nil(@object)
    assert_equal(2, @object.projects.length)
    assert_equal(["World domination","A subproject"], @object.projects.map{|i| i.name})
    assert_equal(5, @object.actions.length)
    assert_equal(["Create giant laser beam","Threaten to destroy Barbados","An action","Take over world","Hello there"], @object.actions.map{|i| i.name})
    assert_equal(["email","email-task","errand","hello","testing","there","work"], GTDContexts.contexts)
    assert_equal(7, GTDContexts.contexts.length)
  end
  def test_projects
    test_GTDFile_initialize
    @p1, @p2 = @object.projects
    assert_equal("World domination", @p1.name)
    assert_equal("A subproject", @p2.name)
    assert_equal(@p1,@p2.parent)
    assert_equal(5, @p1.subitems.length)
    @p1.subitems.each do |s|
      assert_equal(@p1, s.parent)
    end
    assert_equal(1,@p2.subitems.length)
  end
  def test_flatten
    test_GTDFile_initialize
    flat = @object.flatten
    assert_equal(9, flat.length)
    flat.each { |item| assert_equal(@object, item.root) }
  end
  def test_actions
    test_projects
    @a1 = @p1.subitems[1]
    assert_equal("Create giant laser beam", @a1.name)
    assert_equal("2006-06-04", @a1.due)
    assert_equal("A note here <http://www.google.com>", @a1.note)
    assert_equal("due", @a1.due_type)
  end
  def test_update
    test_GTDFile_initialize
    l = @object.update!
    assert_equal(11,l)
    assert_equal([0,1,2,3,4,5,6,8,10], @object.flatten.map {|i| i.line})
    assert_not_nil(@object.file)
    @object.flatten.each do |e|
      assert_equal(@object.file,e.file)
    end
  end
  def test_dump_object
    test_GTDFile_initialize
    File.open("#{__dir__}/test_example.gtd") do |f|
      assert_equal(f.read.chomp, @object.dump_object)
    end
  end
  def test_GTD_singleton_calls
    contexts = GTDContexts.contexts
    GTD.process_directory
    @na = GTD.next_actions
  end
end