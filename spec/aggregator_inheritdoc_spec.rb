require "jsduck/aggregator"
require "jsduck/source_file"
require "jsduck/class"
require "jsduck/relations"
require "jsduck/inherit_doc"

describe JsDuck::Aggregator do

  def parse(string)
    agr = JsDuck::Aggregator.new
    agr.aggregate(JsDuck::SourceFile.new(string))
    relations = JsDuck::Relations.new(agr.result.map {|cls| JsDuck::Class.new(cls) })
    JsDuck::InheritDoc.new(relations).resolve_all
    relations
  end

  shared_examples_for "@inheritdoc" do
    it "original method keeps its name" do
      @orig[:name].should == "bar"
    end

    it "new method keeps its name" do
      @inheritdoc[:name].should == "foobar"
    end

    it "inheritdoc merges comment from original and its own comment" do
      @inheritdoc[:doc].should == "New comment.\n\nOriginal comment."
    end
  end

  describe "@inheritdoc of method" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @method bar
           * Original comment.
           * @param arg1
           * @param arg2
           * @return {String}
           */

        /** @class Core */
          /**
           * @method foobar
           * New comment.
           * @inheritdoc Foo#bar
           */
      EOF
      @orig = @docs["Foo"][:members][:method][0]
      @inheritdoc = @docs["Core"][:members][:method][0]
    end

    it_behaves_like "@inheritdoc"

    it "inherits parameters" do
      @inheritdoc[:params].length.should == 2
    end

    it "inherits return value" do
      @inheritdoc[:return][:type].should == "String"
    end
  end

  describe "@inheritdoc of event" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @event bar
           * Original comment.
           * @param arg1
           * @param arg2
           */

        /** @class Core */
          /**
           * @event foobar
           * New comment.
           * @inheritdoc Foo#bar
           */
      EOF
      @orig = @docs["Foo"][:members][:event][0]
      @inheritdoc = @docs["Core"][:members][:event][0]
    end

    it_behaves_like "@inheritdoc"

    it "inherits parameters" do
      @inheritdoc[:params].length.should == 2
    end

    it "doesn't get return value" do
      @inheritdoc[:return].should == nil
    end
  end

  describe "@inheritdoc of cfg" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @cfg bar
           * Original comment.
           */

        /** @class Core */
          /**
           * @cfg foobar
           * New comment.
           * @inheritdoc Foo#bar
           */
      EOF
      @orig = @docs["Foo"][:members][:cfg][0]
      @inheritdoc = @docs["Core"][:members][:cfg][0]
    end

    it_behaves_like "@inheritdoc"

    it "doesn't get parameters" do
      @inheritdoc[:params].should == nil
    end

    it "doesn't get return value" do
      @inheritdoc[:return].should == nil
    end
  end

  describe "@inheritdoc of static method" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @method bar
           * Original comment.
           * @static
           */

        /** @class Core */
          /**
           * @method foobar
           * New comment.
           * @inheritdoc Foo#bar
           * @static
           */
      EOF
      @orig = @docs["Foo"][:statics][:method][0]
      @inheritdoc = @docs["Core"][:statics][:method][0]
    end

    it_behaves_like "@inheritdoc"
  end

  describe "@inheritdoc with type info" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @cfg bar
           * Original comment.
           */
          /**
           * @method bar
           * Method comment.
           */
          /**
           * @property bar
           * Prop comment.
           */

        /** @class Core */
          /**
           * @cfg foobar
           * New comment.
           * @inheritdoc Foo#cfg-bar
           */
      EOF
      @orig = @docs["Foo"][:members][:cfg][0]
      @inheritdoc = @docs["Core"][:members][:cfg][0]
    end

    it_behaves_like "@inheritdoc"
  end

  describe "@inheritdoc without type info uses the type of itself" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @cfg bar
           * Original comment.
           */
          /**
           * @method bar
           * Method comment.
           */
          /**
           * @property bar
           * Prop comment.
           */

        /** @class Core */
          /**
           * @cfg foobar
           * New comment.
           * @inheritdoc Foo#bar
           */
      EOF
      @orig = @docs["Foo"][:members][:cfg][0]
      @inheritdoc = @docs["Core"][:members][:cfg][0]
    end

    it_behaves_like "@inheritdoc"
  end

  describe "recursive @inheritdocs" do
    before do
      @docs = parse(<<-EOF)
        /** @class Foo */
          /**
           * @method bar
           * Original comment.
           * @param arg1
           * @param arg2
           * @return {String}
           */

        /** @class HyperCore */
          /**
           * @method zap
           * New comment 2.
           * @inheritdoc Core#foobar
           */

        /** @class Core */
          /**
           * @method foobar
           * New comment.
           * @inheritdoc Foo#bar
           */
      EOF
      @orig = @docs["Foo"][:members][:method][0]
      @inheritdoc = @docs["Core"][:members][:method][0]
      @inheritdoc2 = @docs["HyperCore"][:members][:method][0]
    end

    it_behaves_like "@inheritdoc"

    it "inheritdoc2 inherits params from first method" do
      @inheritdoc2[:params].length.should == 2
    end
  end

end
