module Api
  module V1
    class StudentsController < BaseController
      before_action :set_student, only: %i[show update]
      before_action :require_write_access!, only: %i[create update]

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
        student = Student.new(student_params)
        student.trainer_id ||= current_user.trainer_id if current_user.personal?
        student.save!
        audit!("student.create", record: student)
        render_data(StudentSerializer.new(student).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/students/:id
      def update
        authorize_student!(@student)
        return if performed?

        @student.update!(student_params)
        audit!("student.update", record: @student)
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
        params.permit(:name, :birth_date, :sex, :height_cm, :email, :phone,
                      :trainer_id, :status, :health_plan, :emergency_contact)
      end
    end
  end
end
