#--
# SES Core Unit Tests
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This file provides unit tests for the SES Core script. These tests are
# provided in order to ensure that the SES Core script continues to function
# properly in the case of script updates or modifications from external sources
# (such as third-party scripts or scripters).
# 
#++
module SES::TestCases
  # ===========================================================================
  # CoreScriptTest - Unit tests for the SES::Script class.
  # ===========================================================================
  class CoreScriptTest < SES::Test::Spec
    describe 'Script' do SES::Script end
    
    it 'initializes with given name' do
      subject.new(:Example).name.must_be_same_as :Example
    end
    
    it 'defines #authors, #name, and #version methods' do
      script = subject.new(:Example)
      [:authors, :name, :version].each do |instance_method|
        script.must_respond_to(instance_method)
      end
    end
    
    it '#authors, #name, and #version return expected values' do
      script = subject.new(:Example)
      [:authors, :name, :version].each do |ivar|
        expectation = script.instance_variable_get('@data')[ivar]
        script.send(ivar).must_equal expectation
      end
    end
    
    it 'initializes with default author and version' do
      script = subject.new(:Example)
      script.authors.must_equal [:Solistra, :Enelvon]
      script.version.must_equal 1.0
    end
    
    it 'initializes with given version and authors' do
      script = subject.new(:Example, 0.1, :Nobody)
      script.authors.must_equal [:Nobody]
      script.version.must_equal 0.1
    end
    
    it '.format appropriately formats symbols' do
      subject.format(:Example_Script).must_be_same_as :"Example Script"
    end
    
    it '.format appropriately formats descriptive symbols' do
      subject.format(:"Example Script").must_be_same_as :Example_Script
    end
    
    it '.format appropriately formats descriptive strings' do
      subject.format('Example Script').must_be_same_as :Example_Script
    end
  end
  # ===========================================================================
  # CoreRegisterTest - Unit tests for the SES::Register module.
  # ===========================================================================
  class CoreRegisterTest < SES::Test::Spec
    describe 'Register' do SES::Register end
    let :script do SES::Script.new(:Example) end
    
    # Cleans the SES::Register entries and entries in the $imported global
    # variable so these tests do not contaminate either.
    def clean(key)
      subject.scripts.delete(key)
      $imported.delete("SES_#{key}".to_sym)
    end
    
    it '.enter adds the passed script to the register' do
      subject.enter(script)
      subject.scripts.values.must_include(script)
      
      clean(script.name)
    end
    
    it '.enter adds formatted script information to $imported' do
      subject.enter(script)
      $imported.keys.must_include(:SES_Example)
      $imported[:SES_Example].must_equal 1.0
      
      clean(script.name)
    end
    
    it '.entries_for finds SES scripts given script name' do
      subject.entries_for(:Core).first.name.must_be_same_as :Core
    end
    
    it '.entries_for finds SES scripts given single author' do
      subject.enter(example_script = SES::Script.new(:Example, 1.0, :Solistra))
      subject.entries_for(:Solistra).must_include example_script
      
      clean(example_script.name)
    end
    
    it '.entries_for finds SES scripts with all given authors' do
      subject.enter(script)
      subject.entries_for(:Solistra, :Enelvon).must_include script
      
      clean(script.name)
    end
    
    it '.entries_for finds SES scripts given version number' do
      subject.enter(script)
      subject.entries_for(script.version).must_include script
      
      clean(script.name)
    end
    
    it '.include? returns expected values' do
      subject.include?(script.name).must_be_same_as false
      subject.enter(script)
      subject.include?(script.name).must_be_same_as true
      
      clean(script.name)
    end
    
    it '.require raises LoadError if requirement is not present' do
      begin
        subject.require({ :Example => 1.0 })
      rescue LoadError ; true else false end
    end
    
    it '.require raises LoadError if requirement is a low version' do
      subject.enter(script)
      begin
        subject.require({ :Example => 2.0 })
      rescue LoadError ; true else false end
      
      clean(script.name)
    end
    
    it '.require returns true if new requirements were met' do
      subject.enter(script)
      subject.require({ script.name => script.version }).must_be_same_as true
      
      clean(script.name)
    end
    
    it '.require returns false if no new requirements met' do
      subject.enter(script)
      subject.require({ script.name => script.version })
      subject.require({ script.name => script.version }).must_be_same_as false
      
      clean(script.name)
    end
  end
  # ===========================================================================
  # CoreExtensionsTest - Unit tests for extensions to VX Ace data structures.
  # ===========================================================================
  class CoreExtensionsTest < SES::Test::Spec
    describe 'Extensions' do SES::Extensions end
    let :event do MockEvent.new end
    let :item  do MockItem.new  end
    
    # Provides a simple "mock" event for testing purposes.
    class MockEvent
      include SES::Extensions::Comments
      attr_reader :list
      
      def initialize
        @list = [
          RPG::EventCommand.new(108, 0, ['<test>']),
          RPG::EventCommand.new(408, 0, ['Second line.'])
        ]
      end
    end
    
    # Provides a simple "mock" item for testing purposes.
    class MockItem
      include SES::Extensions::Notes
      attr_reader :note
      
      def initialize
        @note = '<test>'
      end
    end
    
    it 'provide appropriate methods' do
      subject::Notes.instance_methods.must_include(:scan_ses_notes)
      [:comments, :scan_ses_comments].each do |instance_method|
        subject::Comments.instance_methods.must_include(instance_method)
      end
      [:this, :event].each do |instance_method|
        subject::Interpreter.instance_methods.must_include(instance_method)
      end
    end
    
    it '::Notes#scan_ses_notes scans notes given a String' do
      capture_output do
        item.scan_ses_notes(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Notes#scan_ses_notes scans notes given a Proc' do
      capture_output do
        item.scan_ses_notes(/<test>/ => -> { puts 'Success.' })
      end.must_equal "Success.\n"
    end
    
    it '::Comments#comments returns an array of comments' do
      event.comments.must_equal ['<test>', 'Second line.']
    end
    
    it '::Comments#scan_ses_comments scans comments given a String' do
      capture_output do
        event.scan_ses_comments(/<test>/ => 'puts "Success."')
      end.must_equal "Success.\n"
    end
    
    it '::Comments#scan_ses_comments scans comments given a Proc' do
      capture_output do
        event.scan_ses_comments(/<test>/ => -> { puts 'Success.' })
      end.must_equal "Success.\n"
    end
    
    it '::Interpreter#event returns the given event id instance' do
      $game_map.stub(:events, {1 => event}) do
        Game_Interpreter.new.event(1).must_be_same_as event
      end
    end
    
    it '::Interpreter#event returns event for interpreter' do
      (interpreter = Game_Interpreter.new).setup([], 1)
      $game_map.stub(:events, 1 => event) do
        interpreter.event.must_be_same_as event
      end
    end
    
    it '::Interpreter#event returns interpreter when appropriate' do
      (interpreter = Game_Interpreter.new).event.must_be_same_as interpreter
    end
  end
  # ===========================================================================
  # CoreMethodDataTest - Unit tests for the SES::MethodData module.
  # ===========================================================================
  class CoreMethodDataTest < SES::Test::Spec
    describe 'MethodData' do SES::MethodData end
    
    def clean(type, key)
      subject.send(type).delete(key)
    end
    
    it '.register_alias registers aliases appropriately' do
      subject.register_alias(self, :test_clean, :clean)
      subject.aliases.must_include self
      subject.aliases[self][:clean].must_include :test_clean
      
      clean(:aliases, self)
    end
    
    it '.register_alias returns true with new alias' do
      subject.register_alias(self, :test_clean, :clean).must_equal true
      
      clean(:aliases, self)
    end
    
    it '.register_alias returns false without new alias' do
      subject.register_alias(self, :test_clean, :clean)
      subject.register_alias(self, :test_clean, :clean).must_equal false
      
      clean(:aliases, self)
    end
    
    it '.register_alias ignores Test Case stubbed object aliases' do
      object = Object.new
      object.stub(:object_id, 0) { subject.aliases.cannot_include object }
    end
    
    it '.register_overwrite registers overwrites appropriately' do
      subject.register_overwrite(self, :clean)
      subject.overwrites.must_include self
      subject.overwrites[self].must_include :clean
      
      clean(:overwrites, self)
    end
    
    it '.register_overwrite returns true with new overwrite' do
      subject.register_overwrite(self, :clean).must_equal true
      
      clean(:overwrites, self)
    end
    
    it '.register_overwrite returns false without new overwrite' do
      subject.register_overwrite(self, :clean)
      subject.register_overwrite(self, :clean).must_equal false
      
      clean(:overwrites, self)
    end
  end
  # ===========================================================================
  # CoreModuleTest - Unit tests for the `alias_method` implementation.
  # ===========================================================================
  class CoreModuleTest < SES::Test::Spec
    describe 'Module' do Module end
    
    it '#alias_method automatically registers aliases' do
      class ::String
        alias_method :ses_core_test_reverse, :reverse
      end
      SES::MethodData.aliases.must_include String
      SES::MethodData.aliases[String][:reverse].must_include \
        :ses_core_test_reverse
      
      String.send(:undef_method, :ses_core_test_reverse)
      SES::MethodData.aliases.delete(String)
    end
  end
  # ===========================================================================
  # CoreMethodDataOverwritesTest - Unit tests for the `overwrites` method and
  #   related methods provided by the SES::MethodData::Overwrites module.
  # ===========================================================================
  class CoreMethodDataOverwritesTest < SES::Test::Spec
    describe 'Overwrites' do SES::MethodData::Overwrites end
    
    # Provides a simple mock object for method overwrite testing.
    class MockObject
      def overwrite_this() end
    end
    
    it '#overwrites registers the given overwritten methods' do
      class MockObject
        overwrites :overwrite_this
      end
      SES::MethodData.overwrites.must_include MockObject
      SES::MethodData.overwrites[MockObject].must_include :overwrite_this
      
      SES::MethodData.overwrites.delete(MockObject)
    end
    
    it '#overwrites raises NoMethodError if method did not exist' do
      class MockObject
        begin
          overwrites :no_method
        rescue NoMethodError ; true else false
        end
      end
    end
    
    it '#overwrites without arguments registers the next method' do
      class MockObject
        overwrites
        def overwrite_this() end
        def overwrite_that() end
      end
      SES::MethodData.overwrites.must_include(MockObject)
      SES::MethodData.overwrites[MockObject].must_include :overwrite_this
      SES::MethodData.overwrites[MockObject].cannot_include :overwrite_that
      
      SES::MethodData.overwrites.delete(MockObject)
    end
  end
end