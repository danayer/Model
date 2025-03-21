project('orbital-calculator', 'vala',
  version: '1.0.0',
  default_options: ['warning_level=2'])

dependencies = [
  dependency('gtk4'),
  meson.get_compiler('c').find_library('m', required: true) # Добавлена библиотека math
]

# Добавляем флаги компилятора для подавления предупреждений в сгенерированном C-коде
c_args = [
  '-Wno-unused-parameter',     # Игнорировать предупреждения о неиспользуемых параметрах
  '-Wno-unused-variable',      # Игнорировать предупреждения о неиспользуемых переменных
  '-Wno-unused-but-set-variable', # Игнорировать предупреждения о переменных, которые установлены но не используются
  '-Wno-discarded-qualifiers'  # Игнорировать предупреждения о отброшенных квалификаторах
]

executable('orbital-calculator',
  'main.vala',
  dependencies: dependencies,
  c_args: c_args,              # Применяем флаги компилятора C
  install: true,
)
