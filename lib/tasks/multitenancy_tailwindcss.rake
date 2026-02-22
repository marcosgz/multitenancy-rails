namespace :multitenancy do
  namespace :tailwindcss do
    desc "Build Tailwind CSS for all multitenancy themes"
    task build: :environment do
      targets = Multitenancy::Integrations::TailwindCss.compilation_targets

      if targets.empty?
        puts "No multitenancy themes with Tailwind CSS found."
        next
      end

      targets.each do |target|
        theme = target[:theme]
        puts "Building Tailwind CSS for theme '#{theme.name}'..."

        command = Multitenancy::Integrations::TailwindCss.compile_command(target, debug: Rails.env.development?)

        system(*command, exception: true)
        puts "  ✓ #{target[:output]}"
      end
    end

    desc "Watch and build Tailwind CSS for all multitenancy themes"
    task watch: :environment do
      targets = Multitenancy::Integrations::TailwindCss.compilation_targets

      if targets.empty?
        puts "No multitenancy themes with Tailwind CSS found."
        next
      end

      pids = targets.map do |target|
        theme = target[:theme]
        puts "Watching Tailwind CSS for theme '#{theme.name}'..."

        command = Multitenancy::Integrations::TailwindCss.watch_command(target, debug: true)

        spawn(*command)
      end

      trap("INT") do
        pids.each { |pid| Process.kill("INT", pid) rescue nil }
        exit
      end

      trap("TERM") do
        pids.each { |pid| Process.kill("TERM", pid) rescue nil }
        exit
      end

      Process.waitall
    end
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance(["multitenancy:tailwindcss:build"])
end
