require 'minitest/autorun'
require 'pandocomatic'

class TestPandocomaticCLI < Minitest::Test

  def setup
  end

  def cli(options_in)
    Pandocomatic::CLI.parse options_in
  end

  def test_version
      assert cli('-v').show_version?
      assert cli('--version').show_version?
      assert cli('-q --version').show_version?
      assert cli('--version test/files/readable_test_file').show_version?
  end

  def test_help
      assert cli('-h').show_help?
      assert cli('-h -q').show_help?
      assert cli('-i test/files/readable_test_file -h').show_help?
      assert cli('--help').show_help?
  end

  def test_version_and_help
      assert cli('-v -h').show_version?
      assert cli('-v -h').show_help?
      assert cli('-v -h').show_help?
  end

  def test_input
    e = assert_raises Pandocomatic::CLIError do
      cli('')
      cli('-i')
      cli('-q')
      cli('-q -i')
    end
    assert_equal e.message, "No input given"

    refute_nil cli('test/files/readable_test_file').input

    refute_nil cli('-i test/files/readable_test_file').input
    
    refute_nil cli('--input test/files/readable_test_file').input
      
    refute_nil cli('-i test/files/readable_test_dir -o /tmp').input

    e = assert_raises Pandocomatic::CLIError do
      cli('test/files/non_existing_file')
      cli('-i test/files/non_existing_file')
      cli('--input test/files/non_existing_file')
    end
    assert_equal e.message, "Input does not exist"

    # TODO: I cannot add "unreadable" files to git. I am not so sure mocking the
    # file system is such a good idea. Creating file and making it unreadable
    # in the test also seems a bit fishy.
    # e = assert_raises Pandocomatic::CLIError do
    #   cli('test/files/unreadable_test_file')
    #   cli('-i test/files/unreadable_test_file')
    #   cli('--input test/files/unreadable_test_file')
    # end
    # assert_equal e.message, Pandocomatic::CLIError::INPUT_IS_NOT_READABLE
  end

  def test_output
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_dir')
    end
    assert_equal e.message, "No output given"
    
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file -o test/files/readable_test_dir')
    end
    assert_equal e.message, "Output is not a file"
    
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_dir -o test/files/readable_test_file')
    end
    assert_equal e.message, "Output is not a directory"
    
    refute cli('--input test/files/readable_test_file').output?
    assert cli('--input test/files/readable_test_file -o test/files/readable_test_file').output?
    assert cli('--input test/files/readable_test_dir -o test').output?
  end

  def test_data_dir
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file -d test/files/non_existing_file')
    end
    assert_equal e.message, "Data dir does not exist"
    
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file -d test/files/readable_test_file')
    end
    assert_equal e.message, "Data dir is not a directory"
    
    # I am unable to commit and push an unreadable directory to git; so this
    # test is switched off for now.
    #
    # e = assert_raises Pandocomatic::CLIError do
    #   cli('-i test/files/readable_test_file -d test/files/unreadable_test_dir')
    # end
    # assert_equal e.message, "Data dir is not readable"

    assert cli('-i test/files/readable_test_file -d test/files/readable_test_dir').data_dir?
  end

  def test_config
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file -c test/files/non_existing_file')
    end
    assert_equal e.message, "Config file does not exist"
    
    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file -c test/files/readable_test_dir')
    end
    assert_equal e.message, "Config file is not a file"
    
    assert cli('-i test/files/readable_test_file -c test/files/config.yaml').config?
  end

  def test_other_options
      assert cli('-i test/files/readable_test_file -y').dry_run?
    assert cli('-i test/files/readable_test_file -q').quiet?
    assert cli('-i test/files/readable_test_file -m').modified_only?
    assert cli('-i test/files/readable_test_file -b').debug?
  end

  def test_problematic_invocation
    e = assert_raises Pandocomatic::CLIError do
      cli('--some-unknown-option')
      cli('-Z')
    end
    assert_equal e.message, "Problematic invocation"
  end

  def test_multiple_input_files
    refute_nil cli('-i test/files/readable_test_file -i test/files/readable_test_file2').input
    
    refute_nil cli('test/files/readable_test_file test/files/readable_test_file2').input

    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_file test/files/readable_test_file2')
    end

    assert_equal e.message, "No mixed inputs"

    e = assert_raises Pandocomatic::CLIError do
      cli('-i test/files/readable_test_dir -i test/files/readable_test_file')
    end

    assert_equal e.message, "Multiple input files only"
  end

end
