# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tag::Item do
  subject(:item) { create(:'tag/item') }

  describe '.rename' do
    context 'when given a unique item name' do
      it 'updates the name on the Tag::Item' do
        expect { described_class.rename(id: item.id, name: 'foo') }
          .to change { item.reload.name }.to('foo')
      end

      it 'strips trailing/leading whitespace' do
        expect { described_class.rename(id: item.id, name: '  foo ') }
          .to change { item.reload.name }.to('foo')
      end
    end

    context 'when given a conflicting/existing item name' do
      let!(:item_2) { create(:'tag/item', name: 'foo') }

      context 'with no redundant tags' do
        let!(:tag) { create(:tag, o: Ticket.first, tag_item: item) }

        it 'reassigns all tags from old-name item to new-name item' do
          expect { described_class.rename(id: item.id, name: item_2.name) }
            .to change { tag.reload.tag_item }.to(item_2)
            .and change { Ticket.first.tag_list }.to([item_2.name])
        end

        it 'strips trailing/leading whitespace' do
          expect { described_class.rename(id: item.id, name: "  #{item_2.name} ") }
            .to change { tag.reload.tag_item }.to(item_2)
            .and change { Ticket.first.tag_list }.to([item_2.name])
        end
      end

      context 'with redundant tags' do
        let!(:tags) do
          [create(:tag, o: Ticket.first, tag_item: item),
           create(:tag, o: Ticket.first, tag_item: item_2)]
        end

        it 'removes the tag assigned to old-name item' do
          expect { described_class.rename(id: item.id, name: item_2.name) }
            .to change { Tag.exists?(id: tags.first.id) }.to(false)
            .and change { Ticket.first.tag_list }.to([item_2.name])
        end

        it 'strips trailing/leading whitespace' do
          expect { described_class.rename(id: item.id, name: "  #{item_2.name} ") }
            .to change { Tag.exists?(id: tags.first.id) }.to(false)
            .and change { Ticket.first.tag_list }.to([item_2.name])
        end
      end

      it 'deletes the original item' do
        expect { described_class.rename(id: item.id, name: item_2.name) }
          .to change { described_class.exists?(name: item.name) }.to(false)
      end
    end

    shared_examples 'updating references to tag names' do |object_klass:, method:, label: 'ticket.tags'|
      subject(:item) { create(:'tag/item', name: 'test1') }

      context "with reference to renamed tag in its #{method} hash (contains-one)" do
        let(:object)      { create(object_klass.name.underscore, method => { label => tag_matcher }) }
        let(:tag_matcher) { { operator: 'contains one', value: 'test1' } }

        it 'updates reference with new tag name' do
          expect { described_class.rename(id: item.id, name: 'test1_renamed') }
            .to change { object.reload.send(method)[label][:value] }
            .from('test1').to('test1_renamed')
        end
      end

      context "with reference to renamed tag in its #{method} hash (contains-all)" do
        let(:object) { create(object_klass.name.underscore, method => { label => tag_matcher }) }
        let(:tag_matcher) { { operator: 'contains all', value: 'test1, test2, test3' } }

        it 'updates reference with new tag name' do
          expect { described_class.rename(id: item.id, name: 'test1_renamed') }
            .to change { object.reload.send(method)[label][:value] }
            .from('test1, test2, test3').to('test1_renamed, test2, test3')
        end
      end
    end

    context 'for Overview object' do
      include_examples 'updating references to tag names', object_klass: Overview, method: :condition
    end

    context 'for Trigger object' do
      include_examples 'updating references to tag names', object_klass: Trigger, method: :condition
      include_examples 'updating references to tag names', object_klass: Trigger, method: :perform
    end

    context 'for scheduler (Job) object' do
      include_examples 'updating references to tag names', object_klass: Job, method: :condition
      include_examples 'updating references to tag names', object_klass: Job, method: :perform
    end

    context 'for PostmasterFilter object' do
      include_examples 'updating references to tag names', object_klass: PostmasterFilter, method: :perform, label: 'x-zammad-ticket-tags'
    end
  end

  describe '.remove' do
    let!(:tags) do
      [create(:tag, tag_item: item, o: User.first),
       create(:tag, tag_item: item, o: Ticket.first)]
    end

    it 'removes the specified Tag::Item' do
      expect { described_class.remove(item.id) }
        .to change { described_class.exists?(id: item.id) }.to(false)
    end

    it 'removes all associated Tags' do
      expect { described_class.remove(item.id) }
        .to change { Tag.exists?(id: tags.first.id) }.to(false)
        .and change { Tag.exists?(id: tags.second.id) }.to(false)
    end
  end

  describe '.filter_or_recommended' do
    before do
      allow(described_class).to receive(:recommended)
      allow(described_class).to receive(:filter_by_name)
    end

    it 'calls filter_by_name when query is present' do
      described_class.filter_or_recommended('query')
      expect(described_class).to have_received(:filter_by_name)
    end

    it 'calls recommended when query is empty' do
      described_class.filter_or_recommended('')
      expect(described_class).to have_received(:recommended)
    end
  end

  describe '.recommended' do
    before do
      create(:tag, o: create(:ticket), tag: 'once')
      3.times { create(:tag, o: create(:ticket), tag: 'thrice') }
      2.times { create(:tag, o: create(:ticket), tag: 'twice') }
    end

    it 'returns items descending by occurrence count' do
      expect(described_class.recommended.pluck(:name))
        .to eq(%w[thrice twice once])
    end
  end

  describe '.filter_by_name' do
    before do
      %w[tag test qwerty].each do |elem|
        create(:tag_item, name: elem)
      end
    end

    it 'returns items descending by occurrence count' do
      expect(described_class.filter_by_name('e').pluck(:name))
        .to eq(%w[qwerty test])
    end
  end

  describe 'validations' do
    it 'does not allow comma in name' do
      item = described_class.new(name: 'tag,with,comma')
      item.valid?

      expect(item.errors[:name]).to be_present
    end

    it 'does not allow asterisk in name' do
      item = described_class.new(name: 'tag*with*asterisk')
      item.valid?

      expect(item.errors[:name]).to be_present
    end
  end
end
