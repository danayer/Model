project('lissajous-model', 'vala', 'c',
  version: '1.0.0',
  meson_version: '>= 0.50.0',
)

# Добавляем зависимости от GTK4
dependencies = [
  dependency('gtk4'),
  dependency('gee-0.8')
]

# Добавляем математическую библиотеку (для sin, cos и других функций)
math_lib = meson.get_compiler('c').find_library('m', required: true)

# Добавляем флаги компилятора для игнорирования предупреждений
c_args = []
vala_args = []

# Игнорируем предупреждение о volatile qualifier
c_args += ['-Wno-discarded-qualifiers']

# Игнорируем предупреждение о неиспользуемых переменных
c_args += ['-Wno-unused-variable']

# Компилируем
executable('lissajous-model',
  'main.vala',
  dependencies: dependencies + [math_lib],
  c_args: c_args,
  vala_args: vala_args,
  install: true,
)
