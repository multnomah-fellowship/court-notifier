require 'mechanize'
require 'json'

class CourtScheduleScraper
  def cases_for(date)
    return to_enum(:cases_for, date) unless block_given?

    mech = Mechanize.new
    page = mech.get('https://publicaccess.courts.oregon.gov/PublicAccess/default.aspx')
    page = mech.post('https://publicaccess.courts.oregon.gov/PublicAccess/Search.aspx?ID=900',
                     NodeID: '104100,104210,104215,104220,104225,104310,104320,104330,104410,104420,104430,104440',
                     NodeDesc: 'Multnomah')

    search_params = {
      :__EVENTTARGET => '',
      :__EVENTARGUMENT => '',
      NodeID: '104100,104210,104215,104220,104225,104310,104320,104330,104410,104420,104430,104440',
      NodeDesc: 'Multnomah',
      SearchBy: '5',
      CaseSearchMode: 'CaseNumber',
      PartySearchMode: 'Name',
      AttorneySearchMode: 'Name',
      cboState: 'AA',
      CaseStatusType: '0',
      cboJudOffc: '19549',
      chkCriminal: 'on',
      chkFamily: 'on',
      chkCivil: 'on',
      chkProbate: 'on',
      chkDtRangeCriminal: 'on',
      chkDtRangeFamily: 'on',
      chkDtRangeCivil: 'on',
      chkDtRangeProbate: 'on',
      cboMagist: '49635',
      chkCriminalMagist: 'on',
      chkFamilyMagist: 'on',
      chkCivilMagist: 'on',
      chkProbateMagist: 'on',
      DateSettingOnAfter: date.strftime('%-m/%d/%Y'),
      DateSettingOnBefore: date.strftime('%-m/%d/%Y'),
      SortBy: 'fileddate',
      SearchSubmit: 'Search',
      SearchType: 'DATERANGE',
      SearchMode: 'DATERANGE',
      StatusType: 'true',
      AllStatusTypes: 'true',
      CaseCategories: 'CR', # CR = Criminal cases only
      SearchParams: 'SearchBy~~Search By:~~Date Range~~Date Range||DateSettingOnAfter~~Date On or After:~~5/17/2017~~5/17/2017||DateSettingOnBefore~~Date On or Before:~~5/17/2017~~5/17/2017||selectSortBy~~Sort By:~~Filed Date~~Filed Date||CaseCategories~~Case Categories:~~CR,CV,FAM,PR~~Criminal, Civil, Family, Probate and Mental Health',
    }

    page = mech.post('https://publicaccess.courts.oregon.gov/PublicAccess/Search.aspx?ID=900', search_params)

    # if there are no cases scheduled, return nothing (probably a weekend)
    if page.css('body').text =~ /No cases matched/
      return
    end

    if error = error_message(page)
      $stderr.puts "Error occurred: #{error}"
    end

    results = schedule_table(page).css('> tr').map do |row|
      next if skip_row?(row)
      row_to_hash(row)
    end.compact

    results.each do |result|
      yield result
    end

    # attempt to find all the results by changing the pagination a couple times
    if error =~ /too many matches/
      $stderr.puts "Changing sort order to see if more results come through."
      page = mech.post(
        'https://publicaccess.courts.oregon.gov/PublicAccess/CourtCalendarSearchResults.aspx',
        search_params.merge(
          SearchParams: 'SearchBy~~Search By:~~Date Range~~Date Range||DateSettingOnAfter~~Date On or After:~~5/30/2017~~5/30/2017||DateSettingOnBefore~~Date On or Before:~~5/30/2017~~5/30/2017||selectSortBy~~Sort By:~~Filed Date~~Filed Date||CaseCategories~~Case Categories:~~CR~~Criminal',
          SortType: 'DT'
        )
      )

      new_results = schedule_table(page).css('> tr').map do |row|
        next if skip_row?(row)
        row_to_hash(row)
      end.compact - results

      $stderr.puts "  ...got #{new_results.length} other results"

      new_results.each do |new_result|
        yield new_result
      end
    end
  end

  def skip_row?(row)
    return true if row.text =~ /Case Number/ # skip header row
    return true if row.text =~ /too many matches/ # skip error row
    return true if row.css('> td').length == 1 # e.g. error or a header grouping cases
  end

  def row_to_hash(row)
    {
      case_number: row.css('td:nth-child(1) tr:nth-child(1) td').text,
      type: row.css('td:nth-child(1) tr:nth-child(2) td').text,
      style: row.css('td:nth-child(2)').text,
      judicial_officer: row.css('td:nth-child(3) tr:nth-child(1) td').text,
      physical_location: row.css('td:nth-child(3) tr:nth-child(2) td').text,
      date: row.css('td:nth-child(4) tr:nth-child(1) td').text,
      time: row.css('td:nth-child(4) tr:nth-child(2) td').text,
      hearing_type: row.css('td:nth-child(4) tr:nth-child(3) td').text,
    }
  end

  def error_message(page)
    node = page.css('[style*="color:#FF4040"]').first
    node && node.text
  end

  def schedule_table(page)
    node = page.css('tr[bgcolor="#EEEEEE"]').first
    (node = node.parent) until node.name == 'table'
    node
  end
end

if __FILE__ == $0
  $stdout.puts "Searching cases for #{ARGV[0]}"
  puts JSON.pretty_generate(CourtScheduleScraper.new.cases_for(Date.parse(ARGV[0])).to_a)
end
