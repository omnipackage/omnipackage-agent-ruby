# frozen_string_literal: true

require 'test_helper'

class TestAgent < ::Minitest::Test
  def test_sample_project_build
    result = ::Agent.build(::File.expand_path('sample_project', __dir__))
    puts " -- BUILD RESULTS -- "
    pp result
    puts " -- ENDOF BUILD RESULTS -- "
    result.each do |res|
      assert res.success
      assert ::File.exist?(res.build_log)
      assert ::File.read(res.build_log).size > 0
      assert res.artefacts.size == 1
      res.artefacts.each do |art|
        assert ::File.exist?(art)
      end

      distro = ::Agent::Distro.new(res.build_config.fetch(:distro))
      package_artefact = res.artefacts[0]
      mounts = {
        package_artefact.dirname => '/pack'
      }
      mount_cli = mounts.map do |from, to|
        "--mount type=bind,source=#{from},target=#{to}"
      end.join(' ')
      commands = []
      if distro.rpm?
        commands << "rpm -i /pack/#{package_artefact.basename}"
      elsif distro.deb?
        commands << "dpkg -i /pack/#{package_artefact.basename}"
      end
      commands << '/usr/bin/sample_project'
      cli = <<~CLI
        #{::Agent.runtime} run --entrypoint /bin/sh #{mount_cli} #{distro.image} -c "#{commands.join(' && ')}"
      CLI
      lines = []
      success = ::Agent::Utils::Subprocess.new.execute(cli) do |output_line|
        lines << output_line
      end&.success?
      assert success
      assert_equal "alive 1.3.5", lines[-1]
    end
  end
end
