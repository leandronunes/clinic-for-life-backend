# frozen_string_literal: true

# Seeds the database with data equivalent to the frontend mock API.
# Idempotent: safe to run multiple times.

puts "Seeding Clinic For Life..."

ActiveRecord::Base.transaction do
  # ---------------------------------------------------------------------------
  # Trainers (personals)
  # ---------------------------------------------------------------------------
  trainers = {
    "Rafael Monteiro" => Trainer.find_or_create_by!(email: "rafael@forlife.app") do |t|
      t.name = "Rafael Monteiro"
      t.cpf = "123.456.789-00"
      t.cref = "012345-G/SP"
      t.phone = "(11) 98888-1111"
      t.status = "active"
    end,
    "Beatriz Lima" => Trainer.find_or_create_by!(email: "bia@forlife.app") do |t|
      t.name = "Beatriz Lima"
      t.cpf = "234.567.890-11"
      t.cref = "023456-G/SP"
      t.phone = "(11) 98888-2222"
      t.status = "active"
    end,
    "Carlos Eduardo" => Trainer.find_or_create_by!(email: "cadu@forlife.app") do |t|
      t.name = "Carlos Eduardo"
      t.cpf = "345.678.901-22"
      t.cref = "034567-G/SP"
      t.phone = "(11) 98888-3333"
      t.status = "blocked"
    end,
    "Marina Souza" => Trainer.find_or_create_by!(email: "marina@forlife.app") do |t|
      t.name = "Marina Souza"
      t.cpf = "456.789.012-33"
      t.cref = "045678-G/SP"
      t.phone = "(11) 98888-4444"
      t.status = "inactive"
    end
  }

  # ---------------------------------------------------------------------------
  # Students
  # ---------------------------------------------------------------------------
  students_data = [
    { name: "Julia Ferreira",  birth_date: "1996-05-12", sex: "female", email: "julia@email.com", phone: "(11) 97777-1010", trainer: "Rafael Monteiro", status: "active" },
    { name: "Pedro Augusto",   birth_date: "1989-11-03", sex: "male",   email: "pedro@email.com", phone: "(11) 97777-2020", trainer: "Rafael Monteiro", status: "active" },
    { name: "Ana Carolina",    birth_date: "1992-02-28", sex: "female", email: "ana@email.com",   phone: "(11) 97777-3030", trainer: "Beatriz Lima",    status: "active" },
    { name: "Lucas Pereira",   birth_date: "2000-07-21", sex: "male",   email: "lucas@email.com", phone: "(11) 97777-4040", trainer: "Beatriz Lima",    status: "inactive" },
    { name: "Mariana Costa",   birth_date: "1985-12-09", sex: "female", email: "mari@email.com",  phone: "(11) 97777-5050", trainer: "Rafael Monteiro", status: "active" },
    { name: "Rodrigo Alves",   birth_date: "1978-03-17", sex: "male",   email: "rod@email.com",   phone: "(11) 97777-6060", trainer: "Carlos Eduardo",  status: "active" }
  ]

  students = students_data.each_with_object({}) do |attrs, acc|
    trainer = trainers[attrs[:trainer]]
    student = Student.find_or_create_by!(email: attrs[:email]) do |s|
      s.name = attrs[:name]
      s.birth_date = attrs[:birth_date]
      s.sex = attrs[:sex]
      s.phone = attrs[:phone]
      s.trainer = trainer
      s.status = attrs[:status]
    end
    acc[attrs[:name]] = student
  end

  julia = students["Julia Ferreira"]
  rafael = trainers["Rafael Monteiro"]

  # ---------------------------------------------------------------------------
  # Users / authentication accounts
  # ---------------------------------------------------------------------------
  User.find_or_create_by!(email: "admin@forlife.app") do |u|
    u.name = "Dra. Camila Andrade"
    u.role = "admin"
    u.password = "Admin@2026"
    u.terms_accepted_at = Time.current
  end

  User.find_or_create_by!(email: "personal@forlife.app") do |u|
    u.name = "Rafael Monteiro"
    u.role = "personal"
    u.password = "Personal@2026"
    u.trainer = rafael
    u.terms_accepted_at = Time.current
  end

  User.find_or_create_by!(email: "aluno@forlife.app") do |u|
    u.name = "Julia Ferreira"
    u.role = "student"
    u.password = "Aluno@2026"
    u.student = julia
    u.terms_accepted_at = Time.current
  end

  # ---------------------------------------------------------------------------
  # Workouts and exercises for Julia
  # ---------------------------------------------------------------------------
  yt = ->(id) { "https://www.youtube.com/embed/#{id}" }

  active_workouts = [
    {
      position: 1, title: "Treino A - Peito, Ombro e Triceps", focus: "Empurrar (Push)",
      created_at: "2026-05-01",
      exercises: [
        { name: "Supino reto com barra",       sets: 4, reps: "8-10",  load_kg: 40, rest_seconds: 90, muscle_group: "Peito",       video_url: yt.call("rT7DgCr-3pg"), notes: "Controlar a fase excentrica em 2s." },
        { name: "Supino inclinado halteres",   sets: 3, reps: "10-12", load_kg: 14, rest_seconds: 75, muscle_group: "Peito",       video_url: yt.call("8iPEnn-ltC8") },
        { name: "Desenvolvimento militar",     sets: 4, reps: "8-10",  load_kg: 22, rest_seconds: 90, muscle_group: "Ombro",       video_url: yt.call("qEwKCR5JCog") },
        { name: "Elevacao lateral",            sets: 3, reps: "12-15", load_kg: 7,  rest_seconds: 60, muscle_group: "Ombro",       video_url: yt.call("3VcKaXpzqRo") },
        { name: "Triceps corda na polia",      sets: 4, reps: "12",    load_kg: 18, rest_seconds: 60, muscle_group: "Triceps",     video_url: yt.call("vB5OHsJ3EME") }
      ]
    },
    {
      position: 2, title: "Treino B - Costas e Biceps", focus: "Puxar (Pull)",
      created_at: "2026-05-01",
      exercises: [
        { name: "Puxada frontal",                  sets: 4, reps: "10",    load_kg: 45, rest_seconds: 90, muscle_group: "Costas", video_url: yt.call("CAwf7n6Luuc") },
        { name: "Remada curvada",                  sets: 4, reps: "8-10",  load_kg: 35, rest_seconds: 90, muscle_group: "Costas", video_url: yt.call("vT2GjY_Umpw") },
        { name: "Remada unilateral halter",        sets: 3, reps: "10",    load_kg: 18, rest_seconds: 75, muscle_group: "Costas", video_url: yt.call("pYcpY20QaE8") },
        { name: "Rosca direta barra W",            sets: 4, reps: "10-12", load_kg: 18, rest_seconds: 60, muscle_group: "Biceps", video_url: yt.call("kwG2ipFRgfo") },
        { name: "Rosca alternada banco inclinado", sets: 3, reps: "12",    load_kg: 10, rest_seconds: 60, muscle_group: "Biceps", video_url: yt.call("soxrZlIl35U") }
      ]
    },
    {
      position: 3, title: "Treino C - Pernas e Core", focus: "Membros inferiores",
      created_at: "2026-05-01",
      exercises: [
        { name: "Agachamento livre",     sets: 4, reps: "8-10",  load_kg: 50,  rest_seconds: 120, muscle_group: "Quadriceps", video_url: yt.call("ultWZbUMPL8"), notes: "Profundidade ate 90 graus." },
        { name: "Leg press 45",          sets: 4, reps: "10-12", load_kg: 120, rest_seconds: 90,  muscle_group: "Quadriceps", video_url: yt.call("IZxyjW7MPJQ") },
        { name: "Cadeira flexora",       sets: 3, reps: "12",    load_kg: 30,  rest_seconds: 60,  muscle_group: "Posterior",  video_url: yt.call("1Tq3QdYUuHs") },
        { name: "Stiff com halteres",    sets: 3, reps: "10-12", load_kg: 18,  rest_seconds: 75,  muscle_group: "Posterior",  video_url: yt.call("CN_7cz3P-1U") },
        { name: "Prancha abdominal",     sets: 3, reps: "45s",   load_kg: nil, rest_seconds: 45,  muscle_group: "Core",       video_url: yt.call("ASdvN_XEl_c") }
      ]
    }
  ]

  archived_workouts = [
    {
      position: 1, title: "Treino A (Mar/2026) - Adaptacao", focus: "Adaptacao geral",
      created_at: "2026-03-01", archived_at: "2026-05-01",
      exercises: [
        { name: "Supino reto guiado", sets: 3, reps: "12", load_kg: 25, rest_seconds: 60, muscle_group: "Peito",  video_url: yt.call("rT7DgCr-3pg") },
        { name: "Puxada frontal",     sets: 3, reps: "12", load_kg: 35, rest_seconds: 60, muscle_group: "Costas", video_url: yt.call("CAwf7n6Luuc") }
      ]
    },
    {
      position: 2, title: "Treino B (Jan/2026) - Hipertrofia inicial", focus: "Hipertrofia",
      created_at: "2026-01-10", archived_at: "2026-03-01",
      exercises: [
        { name: "Agachamento Smith", sets: 4, reps: "10", load_kg: 30, rest_seconds: 75, muscle_group: "Quadriceps", video_url: yt.call("ultWZbUMPL8") }
      ]
    }
  ]

  build_workout = lambda do |data, status|
    workout = julia.workouts.find_or_create_by!(title: data[:title]) do |w|
      w.position = data[:position]
      w.focus = data[:focus]
      w.status = status
      w.trainer_name = rafael.name
      w.created_at = data[:created_at]
      w.archived_at = data[:archived_at]
    end
    if workout.exercises.empty?
      data[:exercises].each_with_index do |ex, index|
        workout.exercises.create!(ex.merge(position: index))
      end
    end
    workout
  end

  active_workouts.each { |data| build_workout.call(data, "active") }
  archived_workouts.each { |data| build_workout.call(data, "archived") }

  # ---------------------------------------------------------------------------
  # Bioimpedance evolution measurements for Julia
  # ---------------------------------------------------------------------------
  evolution = [
    { measured_on: "2025-09-01", weight_kg: 72.4, muscle_mass_kg: 28.1, fat_percentage: 31.2, bmi: 25.7 },
    { measured_on: "2025-10-01", weight_kg: 71.6, muscle_mass_kg: 28.6, fat_percentage: 30.1, bmi: 25.4 },
    { measured_on: "2025-11-01", weight_kg: 70.8, muscle_mass_kg: 29.0, fat_percentage: 29.2, bmi: 25.1 },
    { measured_on: "2025-12-01", weight_kg: 70.2, muscle_mass_kg: 29.4, fat_percentage: 28.4, bmi: 24.9 },
    { measured_on: "2026-01-01", weight_kg: 69.5, muscle_mass_kg: 29.9, fat_percentage: 27.5, bmi: 24.6 },
    { measured_on: "2026-02-01", weight_kg: 68.9, muscle_mass_kg: 30.3, fat_percentage: 26.6, bmi: 24.4 },
    { measured_on: "2026-03-01", weight_kg: 68.2, muscle_mass_kg: 30.8, fat_percentage: 25.7, bmi: 24.2 },
    { measured_on: "2026-04-01", weight_kg: 67.6, muscle_mass_kg: 31.2, fat_percentage: 24.9, bmi: 23.9 },
    { measured_on: "2026-05-01", weight_kg: 67.0, muscle_mass_kg: 31.6, fat_percentage: 24.0, bmi: 23.7 },
    { measured_on: "2026-06-01", weight_kg: 66.4, muscle_mass_kg: 32.0, fat_percentage: 23.1, bmi: 23.5 }
  ]

  evolution.each do |point|
    julia.bioimpedance_measurements.find_or_create_by!(measured_on: point[:measured_on]) do |m|
      m.weight_kg = point[:weight_kg]
      m.muscle_mass_kg = point[:muscle_mass_kg]
      m.fat_percentage = point[:fat_percentage]
      m.bmi = point[:bmi]
      m.source = "import"
    end
  end

  # ---------------------------------------------------------------------------
  # Evolution photos (before & after)
  # ---------------------------------------------------------------------------
  photos = [
    { taken_on: "2025-09-01", image_url: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&h=800&fit=crop", weight_kg: 72.4, fat_percentage: 31.2, muscle_mass_kg: 28.1 },
    { taken_on: "2025-12-01", image_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&h=800&fit=crop", weight_kg: 70.2, fat_percentage: 28.4, muscle_mass_kg: 29.4 },
    { taken_on: "2026-03-01", image_url: "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&h=800&fit=crop", weight_kg: 68.2, fat_percentage: 25.7, muscle_mass_kg: 30.8 },
    { taken_on: "2026-06-01", image_url: "https://images.unsplash.com/photo-1594381898411-846e7d193883?w=600&h=800&fit=crop", weight_kg: 66.4, fat_percentage: 23.1, muscle_mass_kg: 32.0 }
  ]

  photos.each do |photo|
    julia.evolution_photos.find_or_create_by!(taken_on: photo[:taken_on]) do |p|
      p.image_url = photo[:image_url]
      p.weight_kg = photo[:weight_kg]
      p.fat_percentage = photo[:fat_percentage]
      p.muscle_mass_kg = photo[:muscle_mass_kg]
    end
  end

  # ---------------------------------------------------------------------------
  # Partners (public showcase)
  # ---------------------------------------------------------------------------
  partners = [
    { name: "NutriVida",         category: "Nutrição",           description: "Consultoria nutricional especializada em performance esportiva.", link: "https://example.com/nutrivida", logo_url: "https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=200&h=200&fit=crop" },
    { name: "FisioMov",          category: "Fisioterapia",       description: "Reabilitacao e prevencao de lesoes para atletas.",                link: "https://example.com/fisiomov",  logo_url: "https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=200&h=200&fit=crop" },
    { name: "Sports Med Center", category: "Medicina Esportiva", description: "Acompanhamento medico esportivo completo.",                       link: "https://example.com/sportsmed", logo_url: "https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=200&h=200&fit=crop" },
    { name: "PureSupp",          category: "Suplementação",      description: "Linha premium de suplementos com certificacao.",                  link: "https://example.com/puresupp",  logo_url: "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=200&h=200&fit=crop" }
  ]

  partners.each do |partner|
    Partner.find_or_create_by!(name: partner[:name]) do |p|
      p.category = partner[:category]
      p.description = partner[:description]
      p.link = partner[:link]
      p.logo_url = partner[:logo_url]
    end
  end
end

puts "Done. Trainers: #{Trainer.count}, Students: #{Student.count}, Users: #{User.count}, " \
     "Workouts: #{Workout.count}, Measurements: #{BioimpedanceMeasurement.count}, " \
     "Partners: #{Partner.count}"
