require 'nokogiri'
require 'bwoken/formatter'

module Bwoken

  class JUnitTestSuite
    attr_accessor :id
    attr_accessor :package
    attr_accessor :host_name
    attr_accessor :name
    attr_accessor :tests
    attr_accessor :failures
    attr_accessor :errors
    attr_accessor :time
    attr_accessor :timestamp

    attr_accessor :test_cases

    def initialize
      self.test_cases = []
      self.tests = 0
      self.failures = 0
      self.errors = 0
    end

    def complete
      self.time = Time.now - self.timestamp
    end

  end

  class JUnitTestCase
    attr_accessor :name
    attr_accessor :classname
    attr_accessor :time
    attr_accessor :error
    attr_accessor :logs

    attr_accessor :start_time

    def initialize
      self.logs = String.new
      self.error = nil
    end

    def complete
      self.time = Time.now - self.start_time
    end

  end

  class JUnitFormatter < Formatter
    attr_accessor :test_suites

    def initialize
      self.test_suites = []
    end

    on :after_script_run do
      generate_report
    end

    on :complete do |line|
      tokens = line.split(' ')
      test_suite = self.test_suites.last
      test_suite.time = tokens[5].sub(';', '')
    end

    on :debug do |line|
      filtered_line = line.sub(/(target\.frontMostApp.+)\.tap\(\)/, "#{'tap'} \\1")
      filtered_line = filtered_line.gsub(/\[("[^\]]*")\]/, "[" + '\1' + "]")
      filtered_line = filtered_line.gsub('()', '')
      filtered_line = filtered_line.sub(/target.frontMostApp.(?:mainWindow.)?/, '')
      tokens = filtered_line.split(' ')

      test_suite = self.test_suites.last
      test_case = test_suite.test_cases.last

      if test_case
        test_case.logs << "\n#{tokens[3].cyan}\t#{tokens[4..-1].join(' ')}"
      end
    end

    on :error do |line|
      @failed = true
      tokens = line.split(' ')

      test_suite = self.test_suites.last
      test_case = test_suite.test_cases.last
      if test_case
        test_case.complete
        test_case.error = tokens[4..-1].join(' ')
      end

      test_suite.errors += 1

    end

    on :fail do |line|
      @failed = true
      tokens = line.split(' ')

      test_suite = self.test_suites.last
      test_case = test_suite.test_cases.last
      if test_case
        test_case.complete
        test_case.error = tokens[4..-1].join(' ')
      end

      test_suite.failures += 1

    end

    on :start do |line|
      tokens = line.split(' ')

      suite = self.test_suites.last
      if suite
        test_case = Bwoken::JUnitTestCase.new
        test_case.name = tokens[4..-1].join(' ')
        test_case.classname = test_case.name
        test_case.start_time = Time.now

        suite.tests+=1
        suite.test_cases << test_case
      end
    end

    on :pass do |line|
      tokens = line.split(' ')

      test_case = self.test_suites.last.test_cases.last
      if test_case
        test_case.complete
        test_case.error = nil
      end
    end

    on :before_script_run do |path|
      tokens = path.split('/')

      new_suite = Bwoken::JUnitTestSuite.new
      new_suite.timestamp = Time.now
      new_suite.host_name = tokens[-2]
      new_suite.name = tokens[-1]
      new_suite.package = new_suite.name
      new_suite.id = self.test_suites.count + 1

      self.test_suites << new_suite

      @failed = false
    end

    on :other do |line|
      nil
    end

    def generate_report
      doc = Nokogiri::XML::Document.new()
      root = Nokogiri::XML::Element.new('testsuites', doc)
      doc.add_child(root)

      result_name = 'unknown'

      self.test_suites.each do |suite|
        result_name = suite.name.gsub /\.js$/, ''

        suite_elm = Nokogiri::XML::Element.new('testsuite', doc)
        suite_elm['id'] = suite.id
        suite_elm['package'] = suite.package
        suite_elm['hostname'] = suite.host_name
        suite_elm['name'] = suite.name
        suite_elm['tests'] = suite.tests
        suite_elm['failures'] = suite.failures
        suite_elm['errors'] = suite.errors
        suite_elm['time'] = suite.time
        suite_elm['timestamp'] = suite.timestamp.to_s

        system_out = ''
        system_err = ''

        suite.test_cases.each do |test_case|
          test_case_elm = Nokogiri::XML::Element.new('testcase', doc)
          test_case_elm['name'] = test_case.name
          test_case_elm['classname'] = test_case.classname
          test_case_elm['time'] = test_case.time

          if test_case.error
            error = Nokogiri::XML::Element.new('error', doc)
            error['type'] = test_case.error
            test_case_elm.add_child(error)
            system_err << "\n\n#{test_case.logs}"
          else
            system_out << "\n\n#{test_case.logs}"
          end

          suite_elm.add_child(test_case_elm)
        end

        suite_elm.add_child("<system-out>#{doc.create_cdata(system_out)}</system-out>")
        suite_elm.add_child("<system-err>#{doc.create_cdata(system_err)}</system-err>")

        root.add_child(suite_elm)

      end

      out_xml = doc.to_xml

      write_results(out_xml, result_name)
    end

    def write_results(xml, suite_name)
      output_path = File.join(Bwoken.results_path, "#{suite_name}_results.xml")
      File.open(output_path, 'w+') do |io|
        io.write(xml)
      end

      puts "\nJUnit report generated to #{output_path}\n\n"
    end


  end
end
