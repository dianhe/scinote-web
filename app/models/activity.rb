class Activity < ActiveRecord::Base
  after_create :generate_notification

  enum type_of: [
    :create_project,
    :rename_project,
    :change_project_visibility,
    :archive_project,
    :restore_project,
    :assign_user_to_project,
    :change_user_role_on_project,
    :unassign_user_from_project,
    :create_module,
    :clone_module,
    :archive_module,
    :restore_module,
    :change_module_description,
    :assign_user_to_module,
    :unassign_user_from_module,
    :create_step,
    :destroy_step,
    :add_comment_to_step,
    :complete_step,
    :uncomplete_step,
    :check_step_checklist_item,
    :uncheck_step_checklist_item,
    :edit_step,
    :add_result,
    :add_comment_to_result,
    :archive_result,
    :edit_result,
    :create_experiment,
    :edit_experiment,
    :archive_experiment,
    :clone_experiment,
    :move_experiment,
    :add_comment_to_project,
    :edit_project_comment,
    :delete_project_comment,
    :add_comment_to_module,
    :edit_module_comment,
    :delete_module_comment,
    :edit_step_comment,
    :delete_step_comment,
    :edit_result_comment,
    :delete_result_comment,
    :destroy_result,
    :load_protocol_from_file,
    :load_protocol_from_repository,
    :revert_protocol,
    :create_report,
    :delete_report,
    :edit_report,
    :assign_sample,
    :unassign_sample,
    :complete_task,
    :uncomplete_task
  ]

  validates :type_of, presence: true
  validates :project, :user, presence: true

  belongs_to :project, inverse_of: :activities
  belongs_to :my_module, inverse_of: :activities
  belongs_to :user, inverse_of: :activities

  private

  def generate_notification
    if %w(assign_user_to_project
          assign_user_to_module unassign_user_from_module).include? type_of
      notification_type = :assignment
    else
      notification_type = :recent_changes
    end

    project_m = "<a href='#{Rails
                             .application
                             .routes
                             .url_helpers
                             .project_path(project)}'>
                  #{project.name}</a>"
    task_m = "| #{I18n.t('search.index.module')}
              <a href='#{Rails
                          .application
                          .routes
                          .url_helpers
                          .protocols_my_module_path(my_module)}'>
              #{my_module.name}</a>" if my_module

    notification = Notification.create(
      type_of: notification_type,
      title:
        ActionController::Base.helpers.sanitize(message, tags: %w(strong a)),
      message:
      ActionController::Base
        .helpers.sanitize(
          "#{I18n.t('search.index.project')} #{project_m} #{task_m}",
          tags: %w(strong a)
        ),
      generator_user_id: user.id
    )

    project.users.each do |project_user|
      next if project_user == user
      next if !project_user.assignments_notification &&
              notification.type_of == 'assignment'
      next if !project_user.recent_notification &&
              notification.type_of == 'recent_changes'
      UserNotification.create(notification: notification, user: project_user)
    end
  end
end
