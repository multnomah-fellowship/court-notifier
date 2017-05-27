# This differ applies the following logic and returns an array of changes to
# make.
#
# step 0. capture a list of all court cases
#
# step 1. remove any court cases that are exactly the same
#
# step 2. remove any court cases where only the `style` is different
#         (typo corrections)
#
# step 3. remove any court cases where only judge/location are different
#         (change of venue)
#
# step 4. remove court cases that are the same except for the datetime
#         (these are actual changes of date)
#
# step 5. only now can we say that an event has been removed. There should be no
#         more events except for the removed ones.
class Differ
  def initialize(before, after)
    @before = before.dup
    @after = after.dup
  end

  def each_change
    return to_enum(:each_change) unless block_given?

    # step 1: remove any court cases that are exactly the same
    # (note that `after` cases have ID fields so we cannot compare directly)
    remove_items(@after.find_all { |item| @before.include?(item_without(item, :id)) })

    # step 2. remove any court cases where only the `style` is different
    # (typo corrections)
    different_style = intersection_except(@before, @after, :style)
    different_style.each do |before, after|
      yield([:changed, { style: [before[:style], after[:style]] } ])
      remove_items(before, after)
    end

    # step 3. remove any court cases where only judge/location are different
    #         (change of venue)
    different_judge = intersection_except(@before, @after, :judicial_officer).to_a
    different_location = intersection_except(@before, @after, :physical_location).to_a
    different_judge_and_location = intersection_except(@before, @after, :judicial_officer, :physical_location).to_a
    different_judge_and_location.each do |(before, after)|
      yield([:changed, {
        judicial_officer: [
          before[:judicial_officer], after[:judicial_officer]
        ],
        physical_location: [
          before[:physical_location], after[:physical_location]
        ],
      }])
      remove_items(before, after)
    end
    different_judge.each do |(before, after)|
      yield([:changed, {
        judicial_officer: [
          before[:judicial_officer], after[:judicial_officer]
        ]
      }])
      remove_items(before, after)
    end
    different_location.each do |(before, after)|
      yield([:changed, {
        physical_location: [
          before[:physical_location], after[:physical_location]
        ]
      }])
      remove_items(before, after)
    end

    # step 4. remove court cases that are the same except for the datetime
    #         (these are actual changes of date)
    # TODO TUESDAY
    #
    # step 5. only now can we say that an event has been removed. There should be no
    #         more events except for the removed ones.
    # TODO TUESDAY

    @after.each do |item|
      yield([:added, item])
    end
  end

  private

  # Remove items with or without IDs
  def remove_items(*items)
    items.flatten.each do |item|
      @before.delete(item_without(item, :id))
      @after.delete_if { |i| item_without(i, :id) == item_without(item, :id) }
    end
  end

  def item_without(item, *fields)
    item.dup.tap do |i|
      fields.flatten.each do |field|
        i.delete(field)
      end
    end
  end

  def all_fields_unequal?(before, after, *fields)
    fields.flatten.all? do |field|
      before[field] != after[field]
    end
  end

  def intersection_except(before, after, *without)
    return to_enum(:intersection_except, before, after, *without) unless block_given?

    before.find_all do |before_item|
      after.any? do |after_item|
        if item_without(before_item, :id, *without) == item_without(after_item, :id, *without) &&
            all_fields_unequal?(before_item, after_item, *without)
          yield [before_item, after_item]
        end
      end
    end
  end
end
