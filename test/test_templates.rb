# frozen_string_literal: true

require "test_helper"

class TestTemplates < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # Template files exist on disk
  # --------------------------------------------------------------------------

  def test_shape_system_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "shape", "system.txt.erb")
    assert File.exist?(path), "shape/system.txt.erb should exist at #{path}"
  end

  def test_shape_user_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "shape", "user.txt.erb")
    assert File.exist?(path), "shape/user.txt.erb should exist at #{path}"
  end

  def test_generate_system_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "generate", "system.txt.erb")
    assert File.exist?(path), "generate/system.txt.erb should exist at #{path}"
  end

  def test_generate_user_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "generate", "user.txt.erb")
    assert File.exist?(path), "generate/user.txt.erb should exist at #{path}"
  end

  # --------------------------------------------------------------------------
  # Template content sanity checks
  # --------------------------------------------------------------------------

  def test_shape_system_template_contains_prompt_engineer
    path = File.join(SelfAgency.configuration.template_directory, "shape", "system.txt.erb")
    content = File.read(path)
    assert_match(/prompt engineer/i, content)
  end

  def test_shape_user_template_contains_erb_variables
    path = File.join(SelfAgency.configuration.template_directory, "shape", "user.txt.erb")
    content = File.read(path)
    %w[class_name ivars methods scope_instruction raw_prompt].each do |var|
      assert_match(/<%=.*#{var}.*%>/, content, "shape/user.txt.erb should reference #{var}")
    end
  end

  def test_generate_system_template_contains_erb_variables
    path = File.join(SelfAgency.configuration.template_directory, "generate", "system.txt.erb")
    content = File.read(path)
    %w[class_name ivars methods].each do |var|
      assert_match(/<%=.*#{var}.*%>/, content, "generate/system.txt.erb should reference #{var}")
    end
  end

  def test_generate_user_template_contains_shaped_spec
    path = File.join(SelfAgency.configuration.template_directory, "generate", "user.txt.erb")
    content = File.read(path)
    assert_match(/<%=.*shaped_spec.*%>/, content)
  end
end
