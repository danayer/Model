/*
 * Моделирование полета снаряда и самолета
 * Переписано на Vala + GTK4 из VB.NET исходного кода
 */

using Gtk;
using Cairo;
using Math;

// Класс для отрисовки траекторий и зон поражения
class AxisDrawingArea : DrawingArea {
    // Тип оси (1 - зона поражения, 4 - траектория)
    public int axis_type = 4;
    // Тип пикселя (1 - снаряд/бомба, 2 - осколок)
    public int pix_type = 1;
    // Размер пикселя
    public double pix_size = 0.05;
    // Названия осей
    public string x_name = "X,м";
    public string y_name = "Y,м";
    // Цвет фона
    public Gdk.RGBA axis_bkcolor;
    // Базовые параметры масштаба
    public double x_base = 1000;
    public double y_base = 1000;
    // Флаг режима рисования (статический или динамический)
    private bool is_static = true;
    
    // Коллекция для хранения точек для отрисовки
    private struct PixelPoint {
        public double x;
        public double y;
        public Gdk.RGBA color;
        public int mode;
    }
    private Gee.ArrayList<PixelPoint?> points;

    // Добавляем переменные для масштабирования и перемещения
    private double view_offset_x = 0;
    private double view_offset_y = 0;
    private double zoom_factor = 1.0;
    private bool is_dragging = false;
    private double drag_start_x = 0;
    private double drag_start_y = 0;

    public AxisDrawingArea() {
        set_draw_func(draw_func);
        set_content_width(500);
        set_content_height(300);
        
        // Инициализация цвета фона
        axis_bkcolor = Gdk.RGBA();
        axis_bkcolor.parse("white");
        
        // Инициализация коллекции точек
        points = new Gee.ArrayList<PixelPoint?>();
        
        // Добавляем обработку событий мыши для масштабирования и перемещения
        var gesture_drag = new GestureDrag();
        gesture_drag.drag_begin.connect(on_drag_begin);
        gesture_drag.drag_update.connect(on_drag_update);
        gesture_drag.drag_end.connect(on_drag_end);
        add_controller(gesture_drag);
        
        var scroll_controller = new EventControllerScroll(EventControllerScrollFlags.BOTH_AXES);
        scroll_controller.scroll.connect(on_scroll);
        add_controller(scroll_controller);
    }

    // Инициализация оси координат
    public void axis_draw() {
        is_static = true;
        points.clear(); // Очистка точек при инициализации
        queue_draw();
    }

    // Переключение к динамическому режиму
    public void stat_to_din() {
        is_static = false;
        queue_draw();
    }

    // Сохранение динамического состояния
    public void din_to_pic() {
        is_static = true;
    }

    // Отрисовка точки
    public void pix_draw(double x, double y, Gdk.RGBA color, int mode) {
        // Добавляем точку в коллекцию для отрисовки
        PixelPoint point = {x, y, color, mode};
        points.add(point);
        queue_draw(); // Запрос перерисовки
    }

    // Обработчики событий перемещения мышью
    private void on_drag_begin(GestureDrag gesture, double start_x, double start_y) {
        is_dragging = true;
        drag_start_x = start_x;
        drag_start_y = start_y;
    }
    
    private void on_drag_update(GestureDrag gesture, double offset_x, double offset_y) {
        if (is_dragging) {
            view_offset_x += offset_x / (zoom_factor * get_width() / x_base);
            view_offset_y -= offset_y / (zoom_factor * get_height() / y_base);
            queue_draw();
        }
    }
    
    private void on_drag_end(GestureDrag gesture, double offset_x, double offset_y) {
        is_dragging = false;
    }
    
    // Обработчик прокрутки для масштабирования
    private bool on_scroll(EventControllerScroll scroll, double dx, double dy) {
        double zoom_delta = (dy > 0) ? 0.9 : 1.1; // уменьшаем при прокрутке вниз, увеличиваем при прокрутке вверх
        zoom_factor *= zoom_delta;
        
        // Ограничиваем предельные значения масштаба
        if (zoom_factor < 0.1) zoom_factor = 0.1;
        if (zoom_factor > 10.0) zoom_factor = 10.0;
        
        queue_draw();
        return true;
    }
    
    // Сброс масштаба и положения просмотра
    public void reset_view() {
        view_offset_x = 0;
        view_offset_y = 0;
        zoom_factor = 1.0;
        queue_draw();
    }

    private void draw_func(DrawingArea area, Cairo.Context cr, int width, int height) {
        // Настройка масштаба с учетом пользовательского масштабирования
        double scale_x = (double)width / x_base * zoom_factor;
        double scale_y = (double)height / y_base * zoom_factor;
        
        // Очищаем холст
        cr.set_source_rgb(axis_bkcolor.red, axis_bkcolor.green, axis_bkcolor.blue);
        cr.paint();
        
        // Сохраняем текущее состояние контекста
        cr.save();
        
        // Смещаем начало координат с учетом масштабирования и перемещения
        double center_x = width / 2 + view_offset_x * scale_x;
        double center_y = height / 2 + view_offset_y * scale_y;
        cr.translate(center_x, center_y);
        
        // Рисуем оси
        cr.set_source_rgb(0, 0, 0);
        cr.set_line_width(1);
        
        // Ось X
        cr.move_to(-center_x, 0);
        cr.line_to(width - center_x, 0);
        cr.stroke();
        
        // Ось Y
        cr.move_to(0, -center_y);
        cr.line_to(0, height - center_y);
        cr.stroke();
        
        // Метки на осях - изменим расстояние между метками в зависимости от масштаба
        double step_div = zoom_factor < 1.0 ? 5.0 / zoom_factor : 5.0;
        double step_x = x_base / step_div;
        double step_y = y_base / step_div;
        
        // Метки на оси X
        for (int i = (int)(-center_x / (step_x * scale_x)) - 1; i <= (int)((width - center_x) / (step_x * scale_x)) + 1; i++) {
            double x = i * step_x * scale_x;
            cr.move_to(x, -5);
            cr.line_to(x, 5);
            cr.stroke();
            cr.move_to(x - 20, 20);
            cr.show_text((i * step_x).to_string());
        }
        
        // Метки на оси Y
        for (int i = (int)(-center_y / (step_y * scale_y)) - 1; i <= (int)((height - center_y) / (step_y * scale_y)) + 1; i++) {
            double y = i * step_y * scale_y;
            cr.move_to(-5, y);
            cr.line_to(5, y);
            cr.stroke();
            cr.move_to(10, y + 5);
            cr.show_text((-i * step_y).to_string());
        }
        
        // Названия осей
        cr.move_to(width - center_x - 50, -10);
        cr.show_text(x_name);
        cr.move_to(10, -center_y + 20);
        cr.show_text(y_name);
        
        // Рисуем все накопленные точки
        foreach (var point in points) {
            double screen_x = point.x * scale_x;
            double screen_y = -point.y * scale_y;
            
            cr.set_source_rgb(point.color.red, point.color.green, point.color.blue);
            
            // Разные типы точек в зависимости от mode
            if (point.mode == 0 || point.mode == 1) {
                // Простая точка
                double point_size = 2.0;
                cr.arc(screen_x, screen_y, point_size, 0, 2 * Math.PI);
                cr.fill();
            } else if (point.mode == 2) {
                // Больше точка для снаряда/самолета
                double obj_size = (pix_type == 1) ? 5.0 : 3.0;
                cr.arc(screen_x, screen_y, obj_size, 0, 2 * Math.PI);
                cr.fill();
            }
        }
        
        // Восстанавливаем состояние контекста
        cr.restore();
    }
}

public class ProjectileModelApp : Gtk.Application {
    // Константы
    const double PI = 3.14;
    const double g = 9.82;
    
    // Время
    private double ts = 0;
    private double delta_t = 0.1;
    
    private double x_base = 1000;
    private double y_base = 1000;
    
    // Параметры снаряда
    private double v0s = 100;           // начальная скорость
    private double xs0 = 0;             // начальная координата x
    private double ys0 = 0;             // начальная координата y
    private double betta = PI / 2;      // угол стрельбы
    private double xs = 0;              // координата x снаряда
    private double ys = 0;              // координата y снаряда
    private double vx_bumm = 0;         // скорость x при взрыве
    private double vy_bumm = 0;         // скорость y при взрыве
    private double x_bumm = 0;          // координата x взрыва
    private double y_bumm = 0;          // координата y взрыва
    private bool bumm_yes = false;      // произошел ли взрыв
    
    // Параметры самолета
    private double tsam = 0;            // время самолета
    private double vx_sam = 50;         // скорость самолета
    private double xsam = 0;            // координата x самолета
    private double ysam = 500;          // координата y самолета
    private bool bomba_yes = false;     // сброшена ли бомба
    
    // Параметры осколков
    private double v0 = 50;             // начальная скорость разлета осколков
    private double x = 0;               // координата x осколка
    private double y = 0;               // координата y осколка
    private double t = 0;               // время после взрыва
    private double alpha = 0;           // угол разлета осколка
    private double delta_alpha = 2 * PI / 40; // шаг угла
    private double fi = 0;
    private double teta = 0;
    private double sn_size = 0.05;      // размер снаряда
    private double sam_size = 0.07;     // размер самолета
    
    // Элементы интерфейса
    private AxisDrawingArea axis1;      // поле для траектории
    private AxisDrawingArea axis2;      // поле для зоны поражения
    private Entry text_v0;              // начальная скорость осколка
    private Entry text_v0s;             // начальная скорость снаряда
    private Entry text_betta;           // угол стрельбы
    private Entry text_deltat;          // шаг по времени
    private Entry text_xbase;           // базовый масштаб
    private Entry text_vxsam;           // скорость самолета или снаряда
    private Entry text_ysam;            // высота самолета
    private Entry text_h_bumm;          // высота взрыва
    private Entry text_h;               // текущая высота
    private CheckButton check_airplane; // переключатель режима (самолет/снаряд)
    private CheckButton check_auto_bumm; // автоматический взрыв
    private Button button_start;        // кнопка старт
    private Button button_stop;         // кнопка стоп
    private Button button_bumm;         // кнопка взрыв
    private Button button_zona;         // кнопка показать зону поражения
    private Button button_bomba;        // кнопка сбросить бомбу
    
    private uint timer_id = 0;          // ID таймера

    // Добавляем кнопки для управления масштабом
    private Button button_reset_view;

    public ProjectileModelApp() {
        Object(application_id: "org.gtk.projectilemodel", flags: ApplicationFlags.DEFAULT_FLAGS);
    }
    
    protected override void activate() {
        // Создаем главное окно
        var window = new ApplicationWindow(this) {
            title = "Моделирование полета снаряда и самолета",
            default_width = 1200,
            default_height = 800
        };
        
        // Основной контейнер - вертикальная компоновка
        var main_box = new Box(Orientation.VERTICAL, 10);
        main_box.set_margin_start(10);
        main_box.set_margin_end(10);
        main_box.set_margin_top(10);
        main_box.set_margin_bottom(10);
        window.set_child(main_box);
        
        // Верхняя часть - графики рядом
        var graphics_box = new Box(Orientation.HORIZONTAL, 10);
        graphics_box.set_hexpand(true);
        graphics_box.set_vexpand(true);
        main_box.append(graphics_box);
        
        // Создаем области для рисования
        axis1 = new AxisDrawingArea();
        axis2 = new AxisDrawingArea();
        
        // Помещаем их в рамки для лучшей визуализации
        var frame_axis1 = new Frame("Траектория полета");
        frame_axis1.set_child(axis1);
        frame_axis1.set_hexpand(true);
        frame_axis1.set_vexpand(true);
        
        var frame_axis2 = new Frame("Зона поражения");
        frame_axis2.set_child(axis2);
        frame_axis2.set_hexpand(true);
        frame_axis2.set_vexpand(true);
        
        graphics_box.append(frame_axis1);
        graphics_box.append(frame_axis2);
        
        // Нижняя часть - элементы управления
        var controls_box = new Box(Orientation.VERTICAL, 10);
        controls_box.set_margin_top(10);
        main_box.append(controls_box);
        
        // Общие элементы управления (переключатели режимов)
        var mode_frame = new Frame("Режим моделирования");
        var mode_box = new Box(Orientation.HORIZONTAL, 10);
        mode_box.set_margin_start(10);
        mode_box.set_margin_end(10);
        mode_box.set_margin_top(10);
        mode_box.set_margin_bottom(10);
        
        check_airplane = new CheckButton.with_label("Режим самолета");
        check_airplane.toggled.connect(on_check_airplane_toggled);
        mode_box.append(check_airplane);
        
        check_auto_bumm = new CheckButton.with_label("Автоматический взрыв");
        mode_box.append(check_auto_bumm);
        
        button_reset_view = new Button.with_label("Сбросить масштаб");
        button_reset_view.clicked.connect(on_reset_view_clicked);
        mode_box.append(button_reset_view);
        
        mode_frame.set_child(mode_box);
        controls_box.append(mode_frame);
        
        // Панель параметров - распределяем параметры в две строки
        var params_box = new Box(Orientation.VERTICAL, 10);
        
        // Верхняя строка параметров
        var params_row1 = new Box(Orientation.HORIZONTAL, 10);
        params_row1.set_homogeneous(true); // Равное распределение
        
        // Группа для параметров снаряда
        var group_snaryad = new Frame("Параметры снаряда");
        var snaryad_box = new Box(Orientation.HORIZONTAL, 10);
        snaryad_box.set_margin_start(10);
        snaryad_box.set_margin_end(10);
        snaryad_box.set_margin_top(10);
        snaryad_box.set_margin_bottom(10);
        
        // Создаем строки для параметров снаряда
        add_param_row(snaryad_box, "Скорость снаряда (м/с):", out text_v0s, "100");
        add_param_row(snaryad_box, "Угол стрельбы (град):", out text_betta, "45");
        group_snaryad.set_child(snaryad_box);
        params_row1.append(group_snaryad);
        
        // Группа для параметров самолета
        var group_airplane = new Frame("Параметры самолета");
        var airplane_box = new Box(Orientation.HORIZONTAL, 10);
        airplane_box.set_margin_start(10);
        airplane_box.set_margin_end(10);
        airplane_box.set_margin_top(10);
        airplane_box.set_margin_bottom(10);
        
        add_param_row(airplane_box, "Скорость самолета (м/с):", out text_vxsam, "50");
        add_param_row(airplane_box, "Высота самолета (м):", out text_ysam, "500");
        group_airplane.set_child(airplane_box);
        params_row1.append(group_airplane);
        
        // Группа для общих параметров
        var group_common1 = new Frame("Параметры осколков и времени");
        var common_box1 = new Box(Orientation.HORIZONTAL, 10);
        common_box1.set_margin_start(10);
        common_box1.set_margin_end(10);
        common_box1.set_margin_top(10);
        common_box1.set_margin_bottom(10);
        
        add_param_row(common_box1, "Скорость осколков (м/с):", out text_v0, "50");
        add_param_row(common_box1, "Шаг времени (с):", out text_deltat, "0.1");
        group_common1.set_child(common_box1);
        params_row1.append(group_common1);
        
        params_box.append(params_row1);
        
        // Нижняя строка параметров
        var params_row2 = new Box(Orientation.HORIZONTAL, 10);
        params_row2.set_homogeneous(true); // Равное распределение
        
        var group_common2 = new Frame("Масштаб и высота");
        var common_box2 = new Box(Orientation.HORIZONTAL, 10);
        common_box2.set_margin_start(10);
        common_box2.set_margin_end(10);
        common_box2.set_margin_top(10);
        common_box2.set_margin_bottom(10);
        
        add_param_row(common_box2, "Масштаб (м):", out text_xbase, "1000");
        add_param_row(common_box2, "Высота взрыва (м):", out text_h_bumm, "0");
        add_param_row(common_box2, "Текущая высота (м):", out text_h, "0");
        text_h.set_editable(false); // Это поле только для чтения
        
        group_common2.set_child(common_box2);
        params_row2.append(group_common2);
        
        params_box.append(params_row2);
        controls_box.append(params_box);
        
        // Кнопки управления
        var buttons_frame = new Frame("Управление моделированием");
        var buttons_box = new Box(Orientation.HORIZONTAL, 10);
        buttons_box.set_margin_start(10);
        buttons_box.set_margin_end(10);
        buttons_box.set_margin_top(10);
        buttons_box.set_margin_bottom(10);
        buttons_box.set_homogeneous(true); // Равное распределение кнопок
        
        button_start = new Button.with_label("Старт");
        button_start.clicked.connect(on_start_clicked);
        buttons_box.append(button_start);
        
        button_stop = new Button.with_label("Стоп");
        button_stop.clicked.connect(on_stop_clicked);
        buttons_box.append(button_stop);
        
        button_bumm = new Button.with_label("Взрыв");
        button_bumm.clicked.connect(on_bumm_clicked);
        buttons_box.append(button_bumm);
        
        button_bomba = new Button.with_label("Сбросить бомбу");
        button_bomba.clicked.connect(on_bomba_clicked);
        button_bomba.sensitive = false;
        buttons_box.append(button_bomba);
        
        button_zona = new Button.with_label("Зона поражения");
        button_zona.clicked.connect(on_zona_clicked);
        buttons_box.append(button_zona);
        
        buttons_frame.set_child(buttons_box);
        controls_box.append(buttons_frame);
        
        // Начальная инициализация
        delta_alpha = 2 * PI / 40;
        betta = PI / 2;
        
        on_check_airplane_toggled(); // Установить правильные состояния
        
        // Заменяем устаревший метод show() на present()
        window.present();
    }
    
    // Добавляем обработчик для кнопки сброса масштаба
    private void on_reset_view_clicked() {
        axis1.reset_view();
        axis2.reset_view();
    }
    
    // Метод для создания ряда параметров обновлен для горизонтального расположения
    private void add_param_row(Box parent, string label_text, out Entry entry_widget, string default_value) {
        var label = new Label(label_text);
        label.set_xalign(0);
        parent.append(label);
        
        entry_widget = new Entry();
        entry_widget.set_text(default_value);
        entry_widget.set_width_chars(8); // Устанавливаем ширину поля
        parent.append(entry_widget);
    }

    // Обработчик переключения режима "самолет/снаряд"
    private void on_check_airplane_toggled() {
        bool is_airplane = check_airplane.get_active();
        
        if (is_airplane) {
            // Режим самолета
            bomba_yes = false;
            bumm_yes = false;
            button_bomba.sensitive = true;
        } else {
            // Режим снаряда
            bomba_yes = true;
            button_bomba.sensitive = false;
        }
    }
    
    // Обновление параметров из полей ввода
    private void new_param() {
        v0 = double.parse(text_v0.get_text());
        ys = 1;
        delta_t = double.parse(text_deltat.get_text());
        x_base = double.parse(text_xbase.get_text());
        
        if (check_airplane.get_active()) {
            // Самолет
            bomba_yes = false;
            v0s = vx_sam;
            betta = 0;
            vx_sam = double.parse(text_vxsam.get_text());
            ysam = double.parse(text_ysam.get_text());
        } else {
            // Снаряд
            bomba_yes = true;
            xs0 = 0;
            ys0 = 0;
            v0s = double.parse(text_v0s.get_text());
            betta = double.parse(text_betta.get_text()) * PI / 180.0;
        }
    }
    
    // Инициализация осей координат
    private void init_axis() {
        sn_size = 0.05;
        sam_size = 0.07;
        x_base = double.parse(text_xbase.get_text());
        y_base = double.parse(text_xbase.get_text());
        
        axis1.axis_type = 4;
        axis1.pix_type = 1;
        axis1.pix_size = sn_size;
        axis1.x_name = "X,м";
        axis1.y_name = "Y,м";
        
        // Правильно инициализируем цвет фона
        axis1.axis_bkcolor = Gdk.RGBA();
        axis1.axis_bkcolor.parse("white");
        
        axis1.x_base = x_base;
        axis1.y_base = y_base;
        axis1.axis_draw();
        
        axis2.axis_type = 1;
        axis2.pix_type = 2;
        axis2.pix_size = 0;
        axis2.x_name = "X,м";
        axis2.y_name = "Z,м";
        axis2.x_base = x_base;
        axis2.y_base = y_base;
        axis2.axis_draw();
    }
    
    // Обработчик нажатия кнопки Старт
    private void on_start_clicked() {
        bumm_yes = false;
        bomba_yes = false;
        button_start.sensitive = false;
        tsam = 0;
        t = 0;
        ts = 0;
        new_param();
        init_axis();
        axis1.stat_to_din();
        
        // Запускаем таймер для анимации
        if (timer_id > 0)
            Source.remove(timer_id);
        timer_id = Timeout.add(50, on_timer_tick);
    }
    
    // Обработчик нажатия кнопки Стоп
    private void on_stop_clicked() {
        if (timer_id > 0) {
            Source.remove(timer_id);
            timer_id = 0;
        }
        button_start.sensitive = true;
    }
    
    // Обработчик события таймера (анимация)
    private bool on_timer_tick() {
        tsam += delta_t;
        if (!check_airplane.get_active())
            ts = tsam;
        else if (bomba_yes)
            ts += delta_t;
        
        // Самолет
        if (check_airplane.get_active()) {
            // Полет бомбы
            if (!bumm_yes && bomba_yes) {
                axis1.pix_type = 1;
                axis1.pix_size = sn_size;
                xs = xs0 + ts * v0s * cos(betta);
                ys = ys0 + ts * v0s * sin(betta) - g * ts * ts / 2;
                text_h.set_text("%.0f".printf(ys));
                
                // Правильно создаем цвет
                var color = Gdk.RGBA();
                color.parse("black");
                axis1.pix_draw(xs, ys, color, 2);
            } else if (bumm_yes) {
                // Осколки
                bumm();
            }
            
            // Полет самолета
            axis1.pix_type = 1;
            axis1.pix_size = sam_size;
            xsam = -x_base + vx_sam * tsam;
            
            // Правильно создаем цвет
            var color_blue = Gdk.RGBA();
            color_blue.parse("blue");
            axis1.pix_draw(xsam, ysam, color_blue, 2);
            
            axis1.din_to_pic();
            axis1.stat_to_din();
        } else { // Снаряд
            if (!bumm_yes) {
                // Полет снаряда
                axis1.pix_type = 1;
                axis1.pix_size = sn_size;
                xs = xs0 + ts * v0s * cos(betta);
                ys = ys0 + ts * v0s * sin(betta) - g * ts * ts / 2;
                text_h.set_text("%.0f".printf(ys));
                
                // Правильно создаем цвет
                var color = Gdk.RGBA();
                color.parse("black");
                axis1.pix_draw(xs, ys, color, 2);
                
                axis1.din_to_pic();
                axis1.stat_to_din();
            } else {
                // Осколки
                bumm();
            }
        }
        
        if (!bumm_yes && ys < 0) {
            Source.remove(timer_id);
            timer_id = 0;
            button_start.sensitive = true;
            return false;  // Останавливаем таймер
        }
        
        if (check_auto_bumm.get_active() && !bumm_yes && 
            Math.fabs(ys - double.parse(text_h_bumm.get_text())) < 5) {
            on_bumm_clicked();
        }
        
        return true;  // Продолжаем таймер
    }
    
    // Расчет полета осколков
    private void bumm() {
        axis1.pix_type = 1;
        axis1.pix_size = 0;
        alpha = 0;
        t += delta_t;
        
        var color_red = Gdk.RGBA();
        color_red.parse("red");
        
        do {
            alpha += delta_alpha;
            x = x_bumm + t * v0 * cos(alpha) + vx_bumm * t;
            y = y_bumm + t * v0 * sin(alpha) + vy_bumm * t - g * t * t / 2;
            if (y > 0) {
                if (check_airplane.get_active()) {
                    axis1.pix_draw(x, y, color_red, 1);
                } else {
                    axis1.pix_draw(x, y, color_red, 0);
                }
            }
        } while (alpha < 2 * PI);
    }
    
    // Обработчик кнопки "Сбросить бомбу"
    private void on_bomba_clicked() {
        bomba_yes = true;
        // Начальные параметры бомбы
        xs0 = xsam;
        ys0 = ysam;
        v0s = vx_sam;
        betta = 0;
        t = 0;
        ts = 0;
    }
    
    // Обработчик кнопки "Зона поражения"
    private void on_zona_clicked() {
        double local_t;
        
        if (timer_id > 0) {
            Source.remove(timer_id);
            timer_id = 0;
        }
        button_start.sensitive = true;
        
        var color_blue = Gdk.RGBA();
        color_blue.parse("blue");
        
        fi = 0;
        teta = 0;
        do {
            teta = 0;
            do {
                if ((v0 * cos(teta) + vy_bumm) * (v0 * cos(teta) + vy_bumm) + 2 * ys * g < 0) 
                    return;
                    
                local_t = ((v0 * cos(teta) + vy_bumm) + 
                           sqrt((v0 * cos(teta) + vy_bumm) * (v0 * cos(teta) + vy_bumm) + 2 * ys * g)) / g;
                           
                x = local_t * (v0 * sin(teta) * cos(fi) + vx_bumm) + xs;
                y = local_t * (v0 * sin(teta) * sin(fi));
                
                axis2.pix_draw(x, y, color_blue, 0);
                teta += delta_alpha;
            } while (teta < PI);
            fi += delta_alpha;
        } while (fi < 2 * PI);
    }
    
    // Обработчик кнопки "Взрыв"
    private void on_bumm_clicked() {
        if (check_airplane.get_active() && !bomba_yes)
            return;
            
        bumm_yes = true;
        y_bumm = ys;
        x_bumm = xs;
        t = 0;
        vx_bumm = v0s * cos(betta);
        vy_bumm = v0s * sin(betta) - g * ts;
    }
    
    public static int main(string[] args) {
        var app = new ProjectileModelApp();
        return app.run(args);
    }
}
