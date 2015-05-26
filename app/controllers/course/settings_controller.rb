class Course::SettingsController < Course::ComponentController
  layout 'course_settings'

  def index
  end

  def update #:nodoc:
    if @course.update_attributes(course_setting_params)
      redirect_to course_settings_path(current_course),
                  success: t('.success', title: current_course.title)
    else
      render 'index'
    end
  end

  private

  def course_setting_params #:nodoc:
    params.require(:course).
      permit(:title, :description, :status, :start_at, :end_at)
  end
end
