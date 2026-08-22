# frozen_string_literal: true

Facter.add(:github_actions_runner) do
  confine kernel: 'Linux'

  setcode do
    unit_files = Dir.glob('{/etc,/usr/lib,/lib}/systemd/system/github-actions-runner.*.service')
    service_paths = unit_files.filter_map do |unit_file|
      working_directory = File.readlines(unit_file, chomp: true).find { |line| line.start_with?('WorkingDirectory=') }
      working_directory&.delete_prefix('WorkingDirectory=')
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    default_paths = Dir.glob('/opt/actions-runner{,-*}/*')
    instances = (service_paths + default_paths).uniq.select do |runner_path|
      File.file?(File.join(runner_path, '.credentials')) && File.file?(File.join(runner_path, '.path'))
    end.sort

    { 'instances' => instances }
  end
end
