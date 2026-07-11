class ExamSerializer
  def initialize(exam)
    @exam = exam
  end

  def as_json(*)
    {
      id: @exam.id.to_s,
      name: @exam.name,
      description: @exam.description,
      file_url: S3Presigner.presign_get_for(@exam.file_url),
      content_type: @exam.content_type,
      size: @exam.size,
      uploaded_at: @exam.uploaded_at&.iso8601
    }
  end
end
