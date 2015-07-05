task default: 'reports:all'

namespace :reports do
  task all: [:fixme_notes, :rubocop] do
    system 'bin/rails_best_practices'
    system 'bin/brakeman'
  end

  task :rubocop do
    system 'bin/rubocop --rails --display-cop-names'
  end

  desc 'Create a report on all notes'
  task :notes do
    puts "\nCollecting all of the standard code notes..."
    system 'bin/rake notes'
    puts "\nCollecting all HACK code notes..."
    system 'bin/rake notes:custom ANNOTATION=HACK'
    puts "\nCollecting all spec code notes..."
    system "grep -rnE 'OPTIMIZE:|OPTIMIZE|FIXME:|FIXME|TODO:|TODO|HACK:|HACK'"\
           ' spec'
    puts "\nCollecting all view code notes..."
    system "grep -rnE 'OPTIMIZE:|OPTIMIZE|FIXME:|FIXME|TODO:|TODO|HACK:|HACK'"\
           ' app/views'
  end

  desc 'Print only FIXME notes'
  task :fixme_notes do
    puts "\nFIXME Notes (These should all be fixed before merging to master):"
    system 'bin/rake notes:fixme'
    system "grep -rnE 'FIXME:|FIXME'"\
           ' spec'
    system "grep -rnE 'FIXME:|FIXME'"\
           ' app/views'
  end

  desc 'Create a coverage report for documentation'
  task :docs do
    system 'rdoc app lib --coverage-report'
  end
end
