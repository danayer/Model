project('temperature-converter', 'vala', 'c')

# Добавляем флаги компилятора для подавления предупреждений
c_args = [
  '-Wno-discarded-qualifiers',  # Убирает предупреждение о volatile qualifier
  '-Wno-unused-variable'        # Убирает предупреждение о неиспользуемых переменных
]

executable(
    'temperature-converter',
    'main.vala',
    dependencies: [
        dependency('gtk4'),
        meson.get_compiler('c').find_library('m', required: true) # Библиотека math
    ],
    c_args: c_args,  # Применяем флаги компилятора
    install: true,
)
