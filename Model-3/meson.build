project('projectile-model', 'vala', 'c',
  version: '1.0.0',
  default_options: [
    'warning_level=2',
    # Добавляем параметры компилятора для подавления предупреждений
    'c_args=-Wno-discarded-qualifiers -Wno-unused-parameter -Wno-unused-variable -Wno-unused-but-set-variable'
  ]
)

# Находим зависимости
gtk_dep = dependency('gtk4')
m_dep = meson.get_compiler('c').find_library('m', required: true)
gee_dep = dependency('gee-0.8')  # Добавляем Gee для коллекций

# Создаем исполняемый файл
executable(
  'projectile-model',
  'main.vala',
  dependencies: [
    gtk_dep,
    m_dep,
    gee_dep
  ],
  # Добавляем дополнительные опции валы для избежания ошибок
  vala_args: ['--target-glib=2.50'],
  install: true
)
