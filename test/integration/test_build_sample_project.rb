# frozen_string_literal: true

require 'test_helper'

class TestBuildSampleProject < ::Minitest::Test
  %w[podman docker].each do |container_runtime|
    ::OmnipackageAgent::Distro.each do |distro|
      define_method("test_#{distro}_#{container_runtime}") do
        build_sample_project(container_runtime, [distro.name])
      end
    end
  end

  private

  def build_sample_project(container_runtime, distros) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    logger = if ::ENV['VERBOSE']
      ::OmnipackageAgent::Logging::Logger.new(outputs: [$stdout])
    else
      ::OmnipackageAgent::Logging::Logger.new(outputs: [])
    end
    config = ::OmnipackageAgent::Config.get(overrides: {
      container_runtime: container_runtime,
      build_dir: "#{::Dir.tmpdir}/omnipackage-integration-test-build-#{container_runtime}"
    })
    # puts "starting #{distros.join(', ')} in #{container_runtime}"
    result = ::OmnipackageAgent::Build.new(logger: logger, config: config).call(::File.expand_path('sample_project', __dir__), distros: distros)
    assert_equal distros.size, result.size, "missing #{distros} result"
    # puts ' -- BUILD RESULTS -- '
    # pp result
    # puts ' -- ENDOF BUILD RESULTS -- '
    result.each do |res|
      unless res.success
        puts "-- #{res.distro.name} build error -- "
        pp res
        if ::File.exist?(res.build_log)
          puts '-- buildlog --'
          puts(::File.read(res.build_log))
          puts '-- end of buildlog --'
        end

        assert res.success
      end

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
        #{config.container_runtime} run --rm --entrypoint /bin/sh #{mount_cli} #{distro.image} -c "#{commands.join(' && ')}"
      CLI
      lines = []
      success = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger).execute(cli) { |output_line| lines << output_line }&.success?

      assert success, lines.join('|') # rubocop: disable Minitest/AssertWithExpectedArgument
      assert_equal 'alive 1.3.5', lines[-1]
      # puts "OK #{distros.join(', ')} in #{container_runtime}"
    end
  end
end
