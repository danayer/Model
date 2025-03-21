using Gtk;
using Cairo;
using Math;

public class LissajousApp : Gtk.Application {
    // Константы
    private const double PI = 3.14159265359;
    
    // Параметры фигуры Лиссажу
    private double x = 0.0;               // координата x
    private double y = 0.0;               // координата y
    private double Ax = 0.0;              // амплитуда по оси x
    private double Ay = 0.0;              // амплитуда по оси y
    private double Omegax = 0.0;          // частота по оси x
    private double Omegay = 0.0;          // частота по оси y
    private double Tx = 0.0;              // период по оси x
    private double Ty = 0.0;              // период по оси y
    private double Fi0x = 0.0;            // начальная фаза по оси x
    private double Fi0y = 0.0;            // начальная фаза по оси y
    private double t = 0.0;               // время
    private double dt = 0.0;              // шаг по времени
    
    // Виджеты интерфейса
    private Gtk.DrawingArea drawing_area;
    private Gtk.Entry entry_Ax;
    private Gtk.Entry entry_Ay;
    private Gtk.Entry entry_Omegax;
    private Gtk.Entry entry_Omegay;
    private Gtk.Entry entry_Fi0x;
    private Gtk.Entry entry_Fi0y;
    private Gtk.Entry entry_dt;
    private Gtk.Label label_Tx;
    private Gtk.Label label_Ty;
    private Gtk.Label label_t;
    private Gtk.Label label_scale;
    
    // Хранение точек
    private Gee.ArrayList<Point?> points;
    
    // Масштабирование и перемещение
    private double scale_factor = 20.0;    // начальный масштаб
    private double pix_size = 2.0;         // размер точки
    private double offset_x = 0.0;         // смещение по X
    private double offset_y = 0.0;         // смещение по Y
    private double drag_start_x = 0.0;     // начальная точка перетаскивания X
    private double drag_start_y = 0.0;     // начальная точка перетаскивания Y
    private bool is_dragging = false;      // флаг перетаскивания
    
    // Таймер
    private uint timer_id = 0;
    private bool animation_running = false;
    
    // Для рисования
    private Cairo.Surface? saved_surface = null;
    
    // Структура для точек
    private struct Point {
        public double x;
        public double y;
        public Gdk.RGBA color;
    }
    
    public LissajousApp() {
        Object(application_id: "org.gtk.lissajousmodel", flags: ApplicationFlags.DEFAULT_FLAGS);
    }
    
    protected override void activate() {
        // Инициализация списка точек
        points = new Gee.ArrayList<Point?>();
        
        // Создаем главное окно
        var window = new Gtk.ApplicationWindow(this) {
            title = "Моделирование фигур Лиссажу",
            default_width = 800,
            default_height = 600
        };
        
        // Основной контейнер
        var main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        window.set_child(main_box);
        
        // Панель управления
        var control_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        control_box.margin_start = 10;
        control_box.margin_end = 10;
        control_box.margin_top = 10;
        control_box.margin_bottom = 10;
        control_box.hexpand = false;
        main_box.append(control_box);
        
        // Создаем правый контейнер для графика и кнопок масштабирования
        var right_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        right_box.hexpand = true;
        right_box.vexpand = true;
        main_box.append(right_box);
        
        // Создаем панель с кнопками масштабирования
        var zoom_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        zoom_box.margin_start = 10;
        zoom_box.margin_end = 10;
        zoom_box.margin_top = 5;
        zoom_box.margin_bottom = 5;
        zoom_box.halign = Gtk.Align.CENTER;
        right_box.append(zoom_box);
        
        // Кнопка уменьшения масштаба
        var button_zoom_out = new Gtk.Button.with_label("−");
        button_zoom_out.clicked.connect(zoom_out);
        zoom_box.append(button_zoom_out);
        
        // Отображение текущего масштаба
        label_scale = new Gtk.Label("Масштаб: 100%");
        zoom_box.append(label_scale);
        
        // Кнопка увеличения масштаба
        var button_zoom_in = new Gtk.Button.with_label("+");
        button_zoom_in.clicked.connect(zoom_in);
        zoom_box.append(button_zoom_in);
        
        // Кнопка сброса масштаба и позиции
        var button_reset_view = new Gtk.Button.with_label("Сбросить вид");
        button_reset_view.clicked.connect(reset_view);
        zoom_box.append(button_reset_view);
        
        // Создаем область для рисования
        drawing_area = new Gtk.DrawingArea();
        drawing_area.hexpand = true;
        drawing_area.vexpand = true;
        drawing_area.set_draw_func(draw_func);
        
        // Устанавливаем минимальный размер области рисования
        drawing_area.set_content_width(500);
        drawing_area.set_content_height(500);
        
        // Настройка событий для области рисования
        setup_drawing_area_events();
        
        // Добавляем область рисования в правый контейнер
        right_box.append(drawing_area);
        
        // Добавляем элементы управления
        
        // Поле для ввода Ax
        control_box.append(new Gtk.Label("Амплитуда по X (Ax):"));
        entry_Ax = new Gtk.Entry();
        entry_Ax.text = "10.0";
        control_box.append(entry_Ax);
        
        // Поле для ввода Ay
        control_box.append(new Gtk.Label("Амплитуда по Y (Ay):"));
        entry_Ay = new Gtk.Entry();
        entry_Ay.text = "10.0";
        control_box.append(entry_Ay);
        
        // Поле для ввода Omegax
        control_box.append(new Gtk.Label("Частота по X (Omegax):"));
        entry_Omegax = new Gtk.Entry();
        entry_Omegax.text = "1.0";
        control_box.append(entry_Omegax);
        
        // Поле для ввода Omegay
        control_box.append(new Gtk.Label("Частота по Y (Omegay):"));
        entry_Omegay = new Gtk.Entry();
        entry_Omegay.text = "2.0";
        control_box.append(entry_Omegay);
        
        // Поле для ввода Fi0x
        control_box.append(new Gtk.Label("Начальная фаза X (Fi0x):"));
        entry_Fi0x = new Gtk.Entry();
        entry_Fi0x.text = "0.0";
        control_box.append(entry_Fi0x);
        
        // Поле для ввода Fi0y
        control_box.append(new Gtk.Label("Начальная фаза Y (Fi0y):"));
        entry_Fi0y = new Gtk.Entry();
        entry_Fi0y.text = "0.0";
        control_box.append(entry_Fi0y);
        
        // Поле для ввода dt
        control_box.append(new Gtk.Label("Шаг по времени (dt):"));
        entry_dt = new Gtk.Entry();
        entry_dt.text = "0.1";
        control_box.append(entry_dt);
        
        // Вывод расчетного периода Tx
        control_box.append(new Gtk.Label("Период по X (Tx):"));
        label_Tx = new Gtk.Label("0.0");
        control_box.append(label_Tx);
        
        // Вывод расчетного периода Ty
        control_box.append(new Gtk.Label("Период по Y (Ty):"));
        label_Ty = new Gtk.Label("0.0");
        control_box.append(label_Ty);
        
        // Вывод текущего времени
        control_box.append(new Gtk.Label("Время (t):"));
        label_t = new Gtk.Label("0.0");
        control_box.append(label_t);
        
        // Кнопки управления
        var button_init = new Gtk.Button.with_label("Инициализация");
        button_init.clicked.connect(init_data);
        control_box.append(button_init);
        
        var button_start = new Gtk.Button.with_label("Старт");
        button_start.clicked.connect(start_animation);
        control_box.append(button_start);
        
        var button_stop = new Gtk.Button.with_label("Стоп");
        button_stop.clicked.connect(stop_animation);
        control_box.append(button_stop);
        
        var button_clear = new Gtk.Button.with_label("Очистить");
        button_clear.clicked.connect(clear_drawing);
        control_box.append(button_clear);
        
        window.present();
    }
    
    // Настройка обработчиков событий для области рисования
    private void setup_drawing_area_events() {
        // Настраиваем обработчик движения мыши
        var motion_controller = new Gtk.EventControllerMotion();
        motion_controller.motion.connect((x, y) => {
            if (is_dragging) {
                // Вычисляем смещение от начальной точки перетаскивания
                double dx = x - drag_start_x;
                double dy = y - drag_start_y;
                
                // Обновляем смещения с учетом масштаба
                offset_x += dx / scale_factor;
                offset_y -= dy / scale_factor; // Инвертируем Y, т.к. в GTK он направлен вниз
                
                // Обновляем начальную точку перетаскивания
                drag_start_x = x;
                drag_start_y = y;
                
                // Очищаем текущую поверхность рисования и создаем новую
                if (saved_surface != null) {
                    saved_surface.finish();
                    saved_surface = null;
                }
                
                // Перерисовываем
                drawing_area.queue_draw();
            }
        });
        
        // Обработчик нажатия кнопки мыши
        var click_controller = new Gtk.GestureClick();
        click_controller.button = 1; // Левая кнопка мыши
        
        click_controller.pressed.connect((n_press, x, y) => {
            // Начало перетаскивания
            is_dragging = true;
            drag_start_x = x;
            drag_start_y = y;
        });
        
        click_controller.released.connect((n_press, x, y) => {
            // Конец перетаскивания
            is_dragging = false;
        });
        
        // Обработчик прокрутки колеса мыши для масштабирования
        var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.BOTH_AXES);
        
        scroll_controller.scroll.connect((dx, dy) => {
            // Масштабирование с помощью колеса мыши (dy положительное - увеличение, отрицательное - уменьшение)
            if (dy < 0) {
                zoom_in();
            } else if (dy > 0) {
                zoom_out();
            }
            
            // Сигнализируем, что мы обработали событие
            return true;
        });
        
        // Добавляем все контроллеры к области рисования
        drawing_area.add_controller(motion_controller);
        drawing_area.add_controller(click_controller);
        drawing_area.add_controller(scroll_controller);
    }
    
    // Увеличение масштаба
    private void zoom_in() {
        scale_factor *= 1.2;
        update_scale_label();
        
        // Пересоздаем поверхность с новым масштабом
        if (saved_surface != null) {
            saved_surface.finish();
            saved_surface = null;
        }
        
        // Перерисовываем
        drawing_area.queue_draw();
    }
    
    // Уменьшение масштаба
    private void zoom_out() {
        scale_factor /= 1.2;
        update_scale_label();
        
        // Пересоздаем поверхность с новым масштабом
        if (saved_surface != null) {
            saved_surface.finish();
            saved_surface = null;
        }
        
        // Перерисовываем
        drawing_area.queue_draw();
    }
    
    // Сброс вида (масштаб и позиция)
    private void reset_view() {
        scale_factor = 20.0;
        offset_x = 0.0;
        offset_y = 0.0;
        update_scale_label();
        
        // Пересоздаем поверхность с исходным масштабом
        if (saved_surface != null) {
            saved_surface.finish();
            saved_surface = null;
        }
        
        // Перерисовываем
        drawing_area.queue_draw();
    }
    
    // Обновление метки с текущим масштабом
    private void update_scale_label() {
        // Форматируем масштаб в проценты
        int scale_percent = (int)(scale_factor / 20.0 * 100);
        label_scale.label = "Масштаб: %d%%".printf(scale_percent);
    }
    
    // Инициализация данных
    private void init_data() {
        // Очищаем список точек
        points.clear();
        
        // Получаем значения из полей ввода
        Ax = double.parse(entry_Ax.text);
        Ay = double.parse(entry_Ay.text);
        Omegax = double.parse(entry_Omegax.text);
        Omegay = double.parse(entry_Omegay.text);
        Fi0x = double.parse(entry_Fi0x.text);
        Fi0y = double.parse(entry_Fi0y.text);
        dt = double.parse(entry_dt.text);
        
        // Расчет периодов
        Tx = (2 * PI) / Omegax;
        Ty = (2 * PI) / Omegay;
        
        // Вывод периодов
        label_Tx.label = "%.2f".printf(Tx);
        label_Ty.label = "%.2f".printf(Ty);
        
        // Сброс времени
        t = 0.0;
        label_t.label = "%.2f".printf(t);
        
        // Расчет начальных координат
        x = Ax * Math.sin(Omegax * t + Fi0x);
        y = Ay * Math.sin(Omegay * t + Fi0y);
        
        // Добавляем первую точку
        add_point(x, y);
        
        // Обновляем область рисования
        drawing_area.queue_draw();
    }
    
    // Функция рисования
    private void draw_func(DrawingArea da, Cairo.Context cr, int width, int height) {
        // Очищаем фон
        cr.set_source_rgb(1, 1, 1);
        cr.paint();
        
        // Рисуем оси
        draw_axes(cr, width, height);
        
        // Если у нас нет точек, просто выходим
        if (points.size == 0) {
            return;
        }
        
        // Рисуем все точки напрямую в контекст, если нет сохраненной поверхности
        if (saved_surface == null) {
            // Создаем новую поверхность для сохранения состояния
            saved_surface = new Cairo.Surface.similar(cr.get_target(), Cairo.Content.COLOR, width, height);
            var memory_cr = new Cairo.Context(saved_surface);
            
            // Заполняем фон
            memory_cr.set_source_rgb(1, 1, 1);
            memory_cr.paint();
            
            // Рисуем оси на поверхности
            draw_axes(memory_cr, width, height);
        }
        
        // Рисуем на сохраненной поверхности
        var memory_cr = new Cairo.Context(saved_surface);
        
        // Рисуем все точки
        foreach (var point in points) {
            // Преобразование координат от центра
            double screen_x = width / 2 + (point.x + offset_x) * scale_factor;
            double screen_y = height / 2 - (point.y + offset_y) * scale_factor; // Инвертируем Y
            
            // Установка цвета точки
            memory_cr.set_source_rgba(point.color.red, point.color.green, point.color.blue, point.color.alpha);
            
            // Рисуем круг вместо точки для лучшей видимости
            memory_cr.arc(screen_x, screen_y, pix_size, 0, 2 * PI);
            memory_cr.fill();
        }
        
        // Отображаем сохраненную поверхность
        cr.set_source_surface(saved_surface, 0, 0);
        cr.paint();
    }
    
    // Рисование осей координат
    private void draw_axes(Cairo.Context cr, int width, int height) {
        // Установка цвета для осей
        cr.set_source_rgb(0, 0, 0);
        cr.set_line_width(1);
        
        // Находим точку пересечения осей с учетом смещения
        double origin_x = width / 2 + offset_x * scale_factor;
        double origin_y = height / 2 - offset_y * scale_factor;
        
        // Горизонтальная ось (X)
        cr.move_to(0, origin_y);
        cr.line_to(width, origin_y);
        cr.stroke();
        
        // Вертикальная ось (Y)
        cr.move_to(origin_x, 0);
        cr.line_to(origin_x, height);
        cr.stroke();
        
        // Метки на осях
        double unit_step = 5.0; // Шаг между метками в единицах координат
        
        // Метки по X
        // Находим левую и правую границу видимой области в координатах модели
        double left_bound = -offset_x - width / (2 * scale_factor);
        double right_bound = -offset_x + width / (2 * scale_factor);
        
        // Находим первую метку, которая будет видна слева
        double first_tick_x = Math.ceil(left_bound / unit_step) * unit_step;
        
        for (double i = first_tick_x; i <= right_bound; i += unit_step) {
            if (Math.fabs(i) < 0.1) continue; // Пропускаем метку около нуля
            
            double screen_x = width / 2 + (i + offset_x) * scale_factor;
            
            // Вертикальная черта метки
            cr.move_to(screen_x, origin_y - 5);
            cr.line_to(screen_x, origin_y + 5);
            cr.stroke();
            
            // Значение метки
            cr.move_to(screen_x - 10, origin_y + 20);
            cr.show_text("%.0f".printf(i));
        }
        
        // Метки по Y
        // Находим верхнюю и нижнюю границу видимой области в координатах модели
        double bottom_bound = -offset_y - height / (2 * scale_factor);
        double top_bound = -offset_y + height / (2 * scale_factor);
        
        // Находим первую метку, которая будет видна снизу
        double first_tick_y = Math.ceil(bottom_bound / unit_step) * unit_step;
        
        for (double i = first_tick_y; i <= top_bound; i += unit_step) {
            if (Math.fabs(i) < 0.1) continue; // Пропускаем метку около нуля
            
            double screen_y = height / 2 - (i + offset_y) * scale_factor;
            
            // Горизонтальная черта метки
            cr.move_to(origin_x - 5, screen_y);
            cr.line_to(origin_x + 5, screen_y);
            cr.stroke();
            
            // Значение метки
            cr.move_to(origin_x + 10, screen_y + 5);
            cr.show_text("%.0f".printf(i));
        }
        
        // Подписи осей
        cr.move_to(width - 20, origin_y - 10);
        cr.show_text("X");
        
        cr.move_to(origin_x + 10, 20);
        cr.show_text("Y");
    }
    
    // Добавление новой точки
    private void add_point(double x, double y) {
        Point p = Point();
        p.x = x;
        p.y = y;
        
        // Создаем красный цвет для точки
        p.color = Gdk.RGBA();
        p.color.parse("red");
        
        points.add(p);
    }
    
    // Запуск анимации
    private void start_animation() {
        if (animation_running) {
            return;
        }
        
        animation_running = true;
        
        // Запускаем таймер
        timer_id = Timeout.add(50, () => {
            // Увеличиваем время
            t += dt;
            label_t.label = "%.2f".printf(t);
            
            // Вычисляем новые координаты
            x = Ax * Math.sin(Omegax * t + Fi0x);
            y = Ay * Math.sin(Omegay * t + Fi0y);
            
            // Добавляем новую точку
            add_point(x, y);
            
            // Для обеспечения корректной отрисовки при перемещении,
            // необходимо пересоздать surface при добавлении новой точки
            if (saved_surface != null) {
                // Пересоздаем surface без получения размеров
                // так как Cairo.Surface в Vala не имеет методов get_width и get_height
                saved_surface.finish();
                saved_surface = null;
            }
            
            // Перерисовываем
            drawing_area.queue_draw();
            
            // Продолжаем таймер
            return animation_running;
        });
    }
    
    // Остановка анимации
    private void stop_animation() {
        animation_running = false;
        
        if (timer_id > 0) {
            Source.remove(timer_id);
            timer_id = 0;
        }
    }
    
    // Очистка рисунка
    private void clear_drawing() {
        // Освобождаем поверхность
        if (saved_surface != null) {
            saved_surface.finish();
            saved_surface = null;
        }
        
        // Очищаем список точек
        points.clear();
        
        // Сброс времени
        t = 0.0;
        label_t.label = "0.0";
        
        // Обновляем рисунок
        drawing_area.queue_draw();
    }
    
    public static int main(string[] args) {
        return new LissajousApp().run(args);
    }
}
