module Api
  module V1
    class StudentsController < BaseController
      before_action :set_student, only: %i[show update destroy renew_cycle]
      # update's own authorize_student! already covers write access (admin,
      # the student's personal, or the student themselves) — require_write_access!
      # here would additionally block students from updating their own profile.
      before_action :require_write_access!, only: %i[create]
      before_action -> { require_role!(:admin) }, only: %i[destroy]

      # GET /api/v1/students
      def index
        students = student_scope.order(:name)
        students = students.where(status: params[:status]) if params[:status].present?
        if params[:query].present?
          query = "%#{params[:query].to_s.strip.downcase}%"
          students = students.where("lower(name) LIKE :q OR lower(email) LIKE :q", q: query)
        end

        render_data(students.map { |student| StudentSerializer.new(student).as_json },
                    meta: { total: students.size })
      end

      # GET /api/v1/students/:id
      def show
        authorize_student!(@student)
        return if performed?

        render_data(StudentSerializer.new(@student).as_json)
      end

      # POST /api/v1/students
      def create
        student = Student.new(student_params.merge(admin_only_params).merge(staff_only_params))
        student.trainer_id ||= current_user.trainer_id if current_user.personal?
        student.save!
        audit!("student.create", record: student)
        render_data(StudentSerializer.new(student).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/students/:id
      def update
        authorize_student!(@student)
        return if performed?

        @student.update!(student_params.merge(admin_only_params).merge(staff_only_params))
        audit!("student.update", record: @student)
        render_data(StudentSerializer.new(@student).as_json)
      end

      # DELETE /api/v1/students/:id
      def destroy
        audit!("student.destroy", record: @student)
        @student.destroy!
        head :no_content
      end

      # POST /api/v1/students/:id/renew_cycle
      #
      # The "Renovar ciclo" action on the Assiduidade dos alunos screen:
      # closes the student's current attendance cycle into an AttendanceCycle
      # history record (recoverable via GET /students/:id/attendance_cycles)
      # and starts a new one from now. Unlike a bare PATCH cycle_started_at
      # (still available to staff via #staff_only_params — used by the "quota
      # change resets the cycle" flow on the aluno edit form, where there's
      # no distinct prior cycle worth archiving), this endpoint guarantees
      # the closing cycle's boundaries are never silently lost.
      def renew_cycle
        authorize_staff_for_student!(@student)
        return if performed?

        if @student.contracted_workouts_per_cycle.blank?
          return render json: { error: "Aluno não possui treinos contratados por ciclo definidos" },
                        status: :unprocessable_content
        end

        now = Time.current
        AttendanceCycle.create!(
          student: @student,
          contracted_workouts_per_cycle: @student.contracted_workouts_per_cycle,
          started_at: @student.cycle_started_at || @student.created_at,
          ended_at: now
        )
        @student.update!(cycle_started_at: now)
        audit!("student.renew_cycle", record: @student)
        render_data(StudentSerializer.new(@student).as_json)
      end

      private

      def set_student
        @student = Student.find(params[:id])
      end

      def student_scope
        return Student.where(trainer_id: current_user.trainer_id) if current_user.personal?
        return Student.where(id: current_user.student_id) if current_user.student?

        Student.all
      end

      def student_params
        params.permit(:name, :birth_date, :sex, :email, :phone,
                      :trainer_id, :status, :health_plan, :emergency_contact)
      end

      # partner_card_enabled is deliberately kept out of student_params: a
      # student can update their own record (see authorize_student!), and a
      # personal can update their own students, but only an admin may toggle
      # this field. Reading params[:partner_card_enabled] directly (rather
      # than permitting it) means a non-admin's request simply never reaches
      # the model, regardless of what they send.
      def admin_only_params
        return {} unless current_user.admin? && params.key?(:partner_card_enabled)

        { partner_card_enabled: params[:partner_card_enabled] }
      end

      # contracted_workouts_per_cycle and cycle_started_at drive the
      # "Assiduidade dos alunos" quota/cycle — a student must not be able to
      # inflate their own quota or reset their own cycle via the
      # self-service profile update that authorize_student! otherwise
      # allows. For archiving the closing cycle before resetting it, use
      # #renew_cycle instead of a bare PATCH.
      def staff_only_params
        return {} unless current_user.admin? || current_user.personal?

        params.permit(:contracted_workouts_per_cycle, :cycle_started_at)
      end
    end
  end
end
