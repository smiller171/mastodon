# frozen_string_literal: true
# == Schema Information
#
# Table name: lists
#
#  id         :integer          not null, primary key
#  account_id :integer
#  title      :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class List < ApplicationRecord
  include Paginable

  belongs_to :account

  has_many :list_accounts, inverse_of: :list, dependent: :destroy
  has_many :accounts, through: :list_accounts

  validates :title, presence: true

  before_destroy :clean_feed_manager

  private

  def clean_feed_manager
    reblog_key       = FeedManager.instance.key(:list, id, 'reblogs')
    reblogged_id_set = Redis.current.zrange(reblog_key, 0, -1)

    Redis.current.pipelined do
      Redis.current.del(FeedManager.instance.key(:list, id))
      Redis.current.del(reblog_key)

      reblogged_id_set.each do |reblogged_id|
        reblog_set_key = FeedManager.instance.key(:list, id, "reblogs:#{reblogged_id}")
        Redis.current.del(reblog_set_key)
      end
    end
  end
end
