# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Course: Experience Points Disbursement' do
  let(:instance) { create(:instance) }

  with_tenant(:instance) do
    let(:course) { create(:course) }
    let(:approved_course_students) { create_list(:course_student, 3, :approved, course: course) }
    let(:course_teaching_assistant) do
      create(:course_teaching_assistant, :approved, course: course)
    end

    before { login_as(user, scope: :user) }

    context 'As a Course Teaching Assistant' do
      let(:user) { course_teaching_assistant.user }

      scenario 'I can filter students by group' do
        group_1, group_2 = create_list(:course_group, 2, course: course)
        group_1_student, group_2_student, ungrouped_student = approved_course_students
        create(:course_group_user, group: group_1, course_user: group_1_student)
        create(:course_group_user, group: group_2, course_user: group_2_student)

        visit disburse_experience_points_course_users_path(course)
        approved_course_students.each do |student|
          expect(page).to have_content_tag_for(student)
        end

        click_link group_1.name
        expect(page).to have_content_tag_for(group_1_student)
        expect(page).not_to have_content_tag_for(group_2_student)
        expect(page).not_to have_content_tag_for(ungrouped_student)
      end

      scenario 'I can disburse experience points' do
        approved_course_students
        unapproved_course_student = create(:course_student, course: course)

        visit disburse_experience_points_course_users_path(course)

        fill_in 'experience_points_disbursement_reason', with: 'a reason'

        student_to_award_points, student_to_set_zero, student_to_leave_blank = \
          approved_course_students

        expect(page).not_to have_content_tag_for(unapproved_course_student)
        expect(page).to have_content_tag_for(student_to_leave_blank)
        within find(content_tag_selector(student_to_award_points)) do
          find('input.points_awarded').set '100'
        end
        within find(content_tag_selector(student_to_set_zero)) do
          find('input.points_awarded').set '00'
        end

        # ExperiencePointsRecord is not created when points_awarded is zero
        expect do
          click_button I18n.t('course.experience_points_disbursement.new.submit')
        end.to change(Course::ExperiencePointsRecord, :count).by(1)

        expect(current_path).to eq(disburse_experience_points_course_users_path(course))
      end
    end
  end
end
