require 'spec_helper'
require 'bwoken/formatters/junit_formatter'

describe Bwoken::JUnitTestSuite do
  describe '#initialize' do
    it 'sets initial state for an instance' do
      expect(subject.test_cases).to be_kind_of Array
      expect(subject.test_cases).to have(0).items
      expect(subject.tests).to eq(0)
      expect(subject.failures).to eq(0)
      expect(subject.errors).to eq(0)
    end
  end

  describe '#complete' do
    it 'calculates the correct elapsed time for a test' do
      subject.timestamp = Time.now
      sleep 0.1
      subject.complete
      expect(subject.time.round(1)).to eq(0.1)
    end
  end

end

describe Bwoken::JUnitTestCase do
  describe '#initialize' do
    it 'sets initial state for an instance' do
      expect(subject.logs).to be_kind_of String
      expect(subject.error).to be_nil
    end

  end

  describe '#complete' do
    it 'calculates the correct elapsed time for a test case' do
      subject.start_time = Time.now
      sleep 0.1
      subject.complete
      expect(subject.time.round(1)).to eq(0.1)
    end
  end
end

describe Bwoken::JUnitFormatter do
  describe '.on' do
    it 'increments tests counter when a test is run' do
      formatter = Bwoken::JUnitFormatter.new
      formatter.test_suites = [Bwoken::JUnitTestSuite.new]
      formatter._on_start_callback('2013-10-25 16:10:01 +0000 Start: test one', formatter)
      expect(formatter.test_suites[0].tests).to eq(1)
    end

    it 'increments failure counter when a test fails' do
      formatter = Bwoken::JUnitFormatter.new
      formatter.test_suites = [Bwoken::JUnitTestSuite.new]
      test_case = Bwoken::JUnitTestCase.new
      test_case.start_time = Time.now
      formatter.test_suites[0].test_cases = [test_case]
      formatter._on_fail_callback('2013-10-25 16:10:01 +0000 Fail: login', formatter)
      expect(formatter.test_suites[0].failures).to eq(1)
    end

    it 'increments error counter when a test error occurs' do
      formatter = Bwoken::JUnitFormatter.new
      formatter.test_suites = [Bwoken::JUnitTestSuite.new]
      test_case = Bwoken::JUnitTestCase.new
      test_case.start_time = Time.now
      formatter.test_suites[0].test_cases = [test_case]
      formatter._on_error_callback('2013-10-25 16:10:01 +0000 Error: login', formatter)
      expect(formatter.test_suites[0].errors).to eq(1)
    end
  end


  describe '#generate_report' do
    it 'outputs a valid XML report for test suites' do
      # Setup
      #===================================================================================================================
      now = Time.new(2013, 10, 25, 10, 34, 51, '-05:00')

      test_suite = Bwoken::JUnitTestSuite.new
      test_suite.id = 'suite id'
      test_suite.package = 'suite package'
      test_suite.host_name = 'suite host_name'
      test_suite.name = 'suite_name.js'
      test_suite.tests = 2
      test_suite.failures = 1
      test_suite.errors = 1
      test_suite.timestamp = now
      test_suite.time = 10.0

      test_case_passed = Bwoken::JUnitTestCase.new
      test_case_passed.name = 'test one'
      test_case_passed.classname = 'TestOne'
      test_case_passed.time = 3.0
      test_case_passed.logs = 'test one logs'

      test_case_failed = Bwoken::JUnitTestCase.new
      test_case_failed.name = 'test two'
      test_case_failed.classname = 'TestTwo'
      test_case_failed.time = 5.0
      test_case_failed.logs = 'test two logs'
      test_case_failed.error = 'case 2 error'

      test_suite.test_cases << test_case_passed
      test_suite.test_cases << test_case_failed

      subject.test_suites = [test_suite]


      # Assert
      #===================================================================================================================
      subject.stub(:write_results) do |xml, suite_name|

        expect(xml).to be_kind_of(String)

        # Check the test suite
        expect(xml.scan(/testsuite\sid="([^"]+)"/)[0]).to include('suite id')
        expect(xml.scan(/hostname="([^"]+)"/)[0]).to include('suite host_name')
        expect(xml.scan(/testsuite.*name="([^"]+)"/)[0]).to include('suite_name.js')
        expect(xml.scan(/testsuite.*tests="([^"]+)"/)[0]).to include('2')
        expect(xml.scan(/testsuite.*failures="([^"]+)"/)[0]).to include('1')
        expect(xml.scan(/testsuite.*errors="([^"]+)"/)[0]).to include('1')
        expect(xml.scan(/testsuite.*time="([^"]+)"/)[0]).to include('10.0')
        expect(xml.scan(/testsuite.*timestamp="([^"]+)"/)[0]).to include('2013-10-25 10:34:51 -0500')

        # Check the test cases
        expect(xml.scan(/testcase.*\sname="([^"]+)"/)[0]).to include('test one')
        expect(xml.scan(/testcase.*\sclassname="([^"]+)"/)[0]).to include('TestOne')
        expect(xml.scan(/testcase.*\stime="([^"]+)"/)[0]).to include('3.0')

        expect(xml.scan(/testcase.*\sname="([^"]+)"/)[1]).to include('test two')
        expect(xml.scan(/testcase.*\sclassname="([^"]+)"/)[1]).to include('TestTwo')
        expect(xml.scan(/testcase.*\stime="([^"]+)"/)[1]).to include('5.0')

        # Check stdout for logs
        expect(xml.scan(/system-out.*\n.*\n.*test one logs/)).to have(1).items
        expect(xml.scan(/system-err.*\n.*\n.*test two logs/)).to have(1).items

        # Ensure that the resultant document passes XSD validation
        xsd = Nokogiri::XML::Schema(File.read(File.expand_path("#{File.dirname(__FILE__)}/../../../support/junit-4.xsd")))
        doc = Nokogiri::XML(xml)

        errors = []
        xsd.validate(doc).each do |error|
          puts "Error: #{error}"
          errors << error
        end

        expect(errors).to have(0).items

      end

      # Test
      #===================================================================================================================

      subject.generate_report

    end
  end
end
