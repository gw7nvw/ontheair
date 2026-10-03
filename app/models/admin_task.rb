class AdminTask < ApplicationRecord

  validate :record_is_unique
  
  def record_is_unique
    dup = AdminTask.where(
      affected_id: affected_id,
      affected_table: affected_table,
      description: description,
      pending: true
    ).exists?
    errors.add(:id, 'Record is duplicate') if dup
  end

end
