# frozen_string_literal: true

require 'test_helper'

class TestAgent < ::Minitest::Test
  def test_build_sample_project # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
    logger = ::OmnipackageAgent::Logging::Logger.new
    result = ::OmnipackageAgent::Build.call(::File.expand_path('sample_project', __dir__), logger: logger)
    puts ' -- BUILD RESULTS -- '
    pp result
    puts ' -- ENDOF BUILD RESULTS -- '
    result.each do |res| # rubocop: disable Metrics/BlockLength
      assert res.success
      assert_path_exists res.build_log
      assert_match(/successfully finished build/, ::File.read(res.build_log))
      assert_equal 1, res.artefacts.size
      res.artefacts.each do |art|
        assert_path_exists art
      end

      distro = ::OmnipackageAgent::Distro.new(res.build_config.fetch(:distro))
      package_artefact = res.artefacts[0]
      mounts = { package_artefact.dirname => '/pack' }
      mount_cli = mounts.map { |from, to| "--mount type=bind,source=#{from},target=#{to}" }.join(' ')
      commands = []
      if distro.rpm?
        commands << "rpm -i /pack/#{package_artefact.basename}"
      elsif distro.deb?
        commands << "dpkg -i /pack/#{package_artefact.basename}"
      else
        raise "unsupported distro #{distro}"
      end
      commands << 'sample_project'
      cli = <<~CLI
        #{::OmnipackageAgent.config.container_runtime} run --rm --entrypoint /bin/sh #{mount_cli} #{distro.image} -c "#{commands.join(' && ')}"
      CLI
      lines = []
      success = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger).execute(cli) { |output_line| lines << output_line }&.success?

      assert success, lines.join('|') # rubocop: disable Minitest/AssertWithExpectedArgument
      assert_equal 'alive 1.3.5', lines[-1]
    end
  end
end
