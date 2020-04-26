#!/usr/bin/env ruby



require 'Nokogiri'
require "Fastlane"

#≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ TestCase Class ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
class TestCase
  attr_accessor :filepath, :name, :linenumber, :duration, :status, :v_vTag

  def initialize
    @linenumber = -1
  end

  def formatted_V_V_Tag
    tag = is_component_test_case ? @v_vTag.gsub('-ComponentTest',"") : @v_vTag.gsub('-IntegrationTest',"")
    return tag
  end

  def identifier
    return ((formatted_V_V_Tag.split('Scenario'))[1]).strip
  end

  def confluence_link
    confluence_url = ""
    test_identifier_page_name = ((identifier.split('-'))[0]).strip
    return confluence_url + CGI.escape("#{test_identifier_page_name}")
  end

  def isPassed
    return (status == "Pass") ? true : false
  end

  def background_color
    return isPassed ? '#C2E791' : '#D98A92'
  end

  def is_component_test_case
    return (@v_vTag.include? "ComponentTest")
  end

  def test_case_type
    return is_component_test_case ? "Component" : "Integration"
  end

end


#≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ TestReport Formatter ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
class TestReport
  attr_accessor :testCases

  def initialize
    @testCases = []
  end

  def test_result_report_file_path
    return ARGV[0]
  end

  def test_cases_root_folder_path
    return ARGV[1]
  end

  def platform
    return "iOS"
  end

  def execution_person
    return (`git log -1 --pretty=format:'%an - %ae'`)
  end

  def build_version_number
    return ARGV[2]
  end

  def device_name
    simulator_info = ARGV[3]
    return (simulator_info.split('|'))[0]
  end

  def device_version
    simulator_info = ARGV[3]
    return (simulator_info.split('|'))[1]
  end

  def device_major_version
    simulator_info = ARGV[3]
    device_version = (simulator_info.split('|'))[1]
    return (device_version.split('.'))[0]
  end

  def execution_date_time
    return (Time.new).to_s
  end

  def current_branch
    return (`git rev-parse --abbrev-ref HEAD`).strip
  end

  def current_commit_hash
    return (`git rev-parse --short HEAD`).strip
  end

  def git_top_level
    return (`git rev-parse --show-toplevel`).strip
  end

  def git_repo
    return "https://github.com/sivasagarpalakurthyiOS/TestApplication.git"
  end

  def git_file_path(test_case)
    file_path = test_case.filepath.split("#{git_top_level}")[1].strip
    return git_repo + current_branch + file_path + '#L' + test_case.linenumber.to_s
  end

  def current_git_commit_url
    return git_repo + current_commit_hash
  end

  def component_test_cases_duration
    result = @testCases.inject(0.0) do |duration, test_case|
      test_case.is_component_test_case ? duration.to_f + test_case.duration.to_f : duration.to_f + 0.0
    end
    return result.round(3).to_s
  end

  def component_test_cases_count
    result = @testCases.inject(0) do |count, test_case|
      test_case.is_component_test_case ? count.to_i + 1 : count.to_i + 0
    end
    return result.to_s
  end

  def integration_test_cases_duration
    result = @testCases.inject(0.0) do |duration, test_case|
      test_case.is_component_test_case == false ? duration.to_f + test_case.duration.to_f : duration.to_f + 0.0
    end
    return result.round(3).to_s
  end

  def integration_test_cases_count
    result = @testCases.inject(0) do |count, test_case|
      test_case.is_component_test_case == false ? count.to_i + 1 : count.to_i + 0
    end
    return result.to_s
  end


  def run
    parse_report_file
    find_test_cases
    find_V_V_Tags
    generate_html_report
  end


  #≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ Parse Unit TestCases Report file ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
  def parse_report_file
    xml_report_file_path = test_result_report_file_path
    xml_report_file_path = xml_report_file_path.strip.gsub('\\','')
    FastlaneCore::UI.important "\n\n✅ Reading #{platform} Test Result file at path: #{xml_report_file_path}\n\n"

    xml_report = Nokogiri::XML(File.open("#{xml_report_file_path}"))
    test_cases = xml_report.xpath("//testcase")
    test_cases.each do |test_case|
      test_case_string = test_case.to_s
      if (test_case_string.include? "testScenario")
        testCase = TestCase.new
        testCase.name = test_case.attr("name").to_s
        testCase.duration = test_case.attr("time").to_s
        testCase.status = (test_case_string.include? "failure") ? "Fail" : "Pass"
        @testCases << testCase
      end
    end
  end

  #≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ Find V&V Tag Inside TestCase file ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
  def find_test_cases()
    root_folder_path = test_cases_root_folder_path
    root_folder_path = root_folder_path.strip.gsub('\\','')
    Dir["#{root_folder_path}**/**/*"].select{|f| File.file?(f) }.each do |filepath|
      if (filepath.include? ".swift")
        find_test_case_name_in_file(filepath)
      end
    end
  end

  def find_test_case_name_in_file(filepath)
    file = File.open(filepath, "r")
    file.each_with_index do |line, index|
      @testCases.each do |testCase|
        if (testCase.linenumber == -1 && (line.include? "#{testCase.name}"))
          testCase.linenumber = index - 1
          testCase.filepath = filepath
        end
      end
    end
    file.close
  end

  def find_V_V_Tags()
    @testCases.each do |testCase|
      lines = File.readlines("#{testCase.filepath}")
      testCase.v_vTag = (lines[testCase.linenumber]).strip
    end
  end

  #≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ Print TestCases Details ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
  def print_test_case(testCase)
      puts ""
      FastlaneCore::UI.success    "+-------------------------------------------------------------------+"
      FastlaneCore::UI.important  "TestCase Implementation Local File Path: #{testCase.filepath}"
      FastlaneCore::UI.important  "TestCase Implementation File V&V Unique Identifier: #{testCase.v_vTag}"
      FastlaneCore::UI.important  "TestCase Implementation Line Number: #{testCase.linenumber}"
      FastlaneCore::UI.success    "TestCase Implementation Current Git Commit Url: #{current_git_commit_url}"
      FastlaneCore::UI.success    "TestCase Executed By User : 👉 #{execution_person}"
      FastlaneCore::UI.success    "TestCase Formatted TestReport V&V Identifier: #{testCase.identifier}"
      FastlaneCore::UI.success    "TestCase Confluence Url: #{testCase.confluence_link}"
      FastlaneCore::UI.success    "TestCase Implementation Method Name: #{testCase.name}"
      FastlaneCore::UI.success    "TestCase Implementation Git File Path: #{git_file_path(testCase)}"
      FastlaneCore::UI.success    "TestCase Type: #{testCase.test_case_type}"
      FastlaneCore::UI.success    "TestCase Execution Duration: #{testCase.duration} seconds"
      FastlaneCore::UI.success    "TestCase Execution Status: #{testCase.status}"
      FastlaneCore::UI.success    "TestCase Component Tests Count: #{component_test_cases_count}"
      FastlaneCore::UI.success    "TestCase Component Tests Execution Time: #{component_test_cases_duration}"
      FastlaneCore::UI.success    "TestCase Integration Tests Count: #{integration_test_cases_count}"
      FastlaneCore::UI.success    "TestCase Integration Tests Execution Time: #{integration_test_cases_duration}"
      FastlaneCore::UI.important  "TestCase Execution Finished on Git Branch & Commit Hash: 👉 #{current_branch} & #{current_commit_hash}"
      FastlaneCore::UI.success    "+-------------------------------------------------------------------+"
      puts ""
  end

  #≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ Generate HTML Report ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
  def generate_html_report()
    html_report = html_report_template % {:platform => platform,
                                          :execution_person => execution_person,
                                          :build_version_number => build_version_number,
                                          :device_name => device_name,
                                          :device_version => device_version,
                                          :execution_date_time => execution_date_time,
                                          :current_git_commit_url => current_git_commit_url,
                                          :current_commit_hash => current_commit_hash,
                                          :component_test_cases_count => component_test_cases_count,
                                          :component_test_cases_duration => component_test_cases_duration,
                                          :integration_test_cases_count => integration_test_cases_count,
                                          :integration_test_cases_duration => integration_test_cases_duration,
                                          :test_cases_row => generate_test_cases_row}

    html_report_file_name = "#{platform}#{device_major_version}-TestExecutionReport.html"
    html_report_folder = "#{File.dirname(File.dirname("#{test_result_report_file_path}"))}/reports"
    html_report_file_path = "#{html_report_folder}/#{html_report_file_name}"
    open(html_report_file_path, 'w+') do |file|
      file.puts html_report
    end
    FastlaneCore::UI.important "\n✅ #{platform} test execution report file has been generated at path: #{html_report_file_path}"
    FastlaneCore::UI.success "\n🚀 Open #{platform} test execution report file as: open #{html_report_file_path}\n\n"
  end

  def generate_test_cases_row()
    result = ""
    sortedTestCases = @testCases.sort_by(&:v_vTag)
    sortedTestCases.each do |testCase|
      print_test_case(testCase)
      result += "\n" + test_case_row_template % {:background_color => testCase.background_color,
                                                 :confluence_link => testCase.confluence_link,
                                                 :identifier => testCase.identifier,
                                                 :git_file_path => git_file_path(testCase),
                                                 :name => testCase.name,
                                                 :type => testCase.test_case_type,
                                                 :duration => testCase.duration,
                                                 :status => testCase.status}
    end
    return result
  end

  #≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠ HTML Report Template ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
  def html_report_template()
      '<!DOCTYPE html>
      <html>
      <head>
        <title>eTeki iOS Test Execution Report</title>
        <style>
        * {
          box-sizing: border-box;
        }

        /* Create columns that floats next to each other */
        .column40 {
          float: left;
          margin: auto;
          width: 40%%;
        }
        .column40Header {
          float: left;
          margin: auto;
          width: 40%%;
          height: 50px;
        }

        .column25 {
          float: left;
          margin: auto;
          width: 25%%;
        }

        .column25Header {
          float: left;
          margin: auto;
          width: 25%%;
          height: 50px;
        }

        .column13 {
          float: left;
          margin: auto;
          width: 13%%;
        }

        .column13Header {
          float: left;
          margin: auto;
          width: 13%%;
          height: 50px;
        }

        .column9 {
          float: left;
          margin: auto;
          width: 9%%;
        }

        .column9Header {
          float: left;
          margin: auto;
          width: 9%%;
          height: 50px;
        }

        /* Clear floats after the columns */
        .row:after {
          content: "";
          display: table;
          clear: both;
        }
        div {
          border-style: solid;
          border-color: #ADD470;
          border-width: 1px 1px 0px 1px;
          height: auto;
        }
        </style>
      </head>
      <body style="color:#4A4A4A;">

        <h2 align="center">eTeki iOS %{platform} Test Execution Report</h2>

        <p><b>Executed By:&nbsp;</b>%{execution_person}<br/>
          <b>Build Version Number:&nbsp;</b>%{build_version_number}<br/>
          <b>Device Details:&nbsp;</b>%{device_name}, iOS %{device_version}<br/>
          <b>Test Execution Date Time:&nbsp;</b>%{execution_date_time}<br/>
          <b>Test Executed on Git Revision:&nbsp;</b><a href="%{current_git_commit_url}">%{current_commit_hash}</a></p>
          <h5 style="color:#467FBB;">Executed %{component_test_cases_count} Component tests 👉 in %{component_test_cases_duration} seconds. 🚀<br/>
          Executed %{integration_test_cases_count} Integration test(s) 📲 in %{integration_test_cases_duration} seconds. 🚗</h5>
          <div class="row">
            <div class="column25Header" style="background-color:#F1F3FA;">
              <p align="center" style="line-height:0px;"><b>Test Case Identifier</b></p>
              <p align="center" style="line-height:0px;">[FeatureId.UserStoryId.Scenario: TC#]</p>
              </div>
            <div class="column40Header" style="background-color:#F1F3FA;">
              <p align="center" style="line-height:0px;"><b>Test Case Method Name</b>
              <p align="center" style="line-height:0px;">[in Swift File]</p>
            </div>
            <div class="column13Header" style="background-color:#F1F3FA;">
              <p align="center" style="line-height:0px;"><b>Type</b>
              <p align="center" style="line-height:0px;">[Component/Integration]</p>
            </div>
            <div class="column13Header" style="background-color:#F1F3FA;">
              <p align="center" style="line-height:0px;"><b>Execution Time</b></p>
              <p align="center" style="line-height:0px;">[in Seconds]</p>
            </div>
            <div class="column9Header" style="background-color:#F1F3FA;">
              <p align="center" style="line-height:0px;"><b>Status</b></p>
              <p align="center" style="line-height:0px;">[Pass/Fail]</p>
            </div>
          </div>

          %{test_cases_row}

      </body>
      </html>'
  end

  def test_case_row_template()
      '<div class="row">
          <div class="column25" style="background-color:%{background_color};">
            <p style="line-height:0px;">&nbsp;<a href="%{confluence_link}">%{identifier}</a></p>
          </div>
          <div class="column40" style="background-color:%{background_color};">
            <p style="line-height:0px;">&nbsp;<a href="%{git_file_path}">%{name}</a></p>
          </div>
          <div class="column13" style="background-color:%{background_color};">
            <p align="center" style="line-height:0px;">&nbsp;%{type}</p>
          </div>
          <div class="column13" style="background-color:%{background_color};">
            <p align="center" style="line-height:0px;">&nbsp;%{duration}</p>
          </div>
          <div class="column9" style="background-color:%{background_color};">
            <p align="center" style="line-height:0px;">&nbsp;%{status}</p>
          </div>
      </div>'
  end

end


TestReport.new.run
