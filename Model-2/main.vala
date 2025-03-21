using Gtk;

public class TemperatureConverter : Gtk.Application {
    // Константы
    private const double k = 1.38e-23; // Постоянная Больцмана, Дж/K
    private const double Pi = 3.14;
    
    // Переменные для температуры в разных шкалах
    private double TK; // Кельвин
    private double TC; // Цельсий
    private double TF; // Фаренгейт
    private double TR; // Реомюр
    private double TE; // Энергия в Джоулях
    
    private double V; // Скорость
    private double m; // Масса

    // Элементы интерфейса
    private Entry entry_tk;
    private Entry entry_tc;
    private Entry entry_tf;
    private Entry entry_tr;
    private Entry entry_te;
    private Entry entry_m;
    private Entry entry_v;
    
    private CheckButton radio_k;
    private CheckButton radio_c;
    private CheckButton radio_f;
    private CheckButton radio_r;
    private CheckButton radio_e;

    public TemperatureConverter() {
        Object(application_id: "com.example.temperature-converter", flags: ApplicationFlags.DEFAULT_FLAGS);
    }

    protected override void activate() {
        // Создание главного окна
        var window = new ApplicationWindow(this) {
            title = "Конвертер температур",
            default_width = 500,
            default_height = 500
        };

        // Создание основного контейнера
        var main_box = new Box(Orientation.VERTICAL, 10) {
            margin_start = 20,
            margin_end = 20,
            margin_top = 20,
            margin_bottom = 20
        };
        window.set_child(main_box);

        // Создание группы радиокнопок
        var radio_box = new Box(Orientation.HORIZONTAL, 10);
        main_box.append(radio_box);
        
        radio_k = new CheckButton.with_label("Кельвины");
        radio_c = new CheckButton.with_label("Цельсии");
        radio_c.set_group(radio_k);
        radio_f = new CheckButton.with_label("Фаренгейты");
        radio_f.set_group(radio_k);
        radio_r = new CheckButton.with_label("Реомюры");
        radio_r.set_group(radio_k);
        radio_e = new CheckButton.with_label("Джоули");
        radio_e.set_group(radio_k);
        
        radio_box.append(radio_k);
        radio_box.append(radio_c);
        radio_box.append(radio_f);
        radio_box.append(radio_r);
        radio_box.append(radio_e);
        radio_k.active = true;

        // Создание полей ввода и меток
        create_labeled_entry(main_box, "Температура (K):", out entry_tk);
        create_labeled_entry(main_box, "Температура (°C):", out entry_tc);
        create_labeled_entry(main_box, "Температура (°F):", out entry_tf);
        create_labeled_entry(main_box, "Температура (°R):", out entry_tr);
        create_labeled_entry(main_box, "Энергия (Дж):", out entry_te);
        create_labeled_entry(main_box, "Масса частицы (кг):", out entry_m);
        create_labeled_entry(main_box, "Скорость (м/с):", out entry_v);
        
        entry_m.set_text("1.67e-27"); // Значение по умолчанию для массы (примерно масса протона)

        // Кнопка для расчетов
        var calc_button = new Button.with_label("Рассчитать") {
            margin_top = 10,
            halign = Align.CENTER
        };
        main_box.append(calc_button);

        // Обработчик кнопки
        calc_button.clicked.connect(() => {
            calculate_temperature();
        });

        // Отображение окна
        window.present();
    }
    
    private void create_labeled_entry(Box box, string label_text, out Entry entry) {
        var hbox = new Box(Orientation.HORIZONTAL, 10);
        var label = new Label(label_text) {
            halign = Align.START,
            width_chars = 20
        };
        
        entry = new Entry() {
            halign = Align.FILL,
            hexpand = true
        };
        
        hbox.append(label);
        hbox.append(entry);
        box.append(hbox);
    }
    
    private void calculate_temperature() {
        // Получение значения массы и проверка на корректность
        if (!validate_double_input(entry_m.get_text(), out m)) {
            show_error_dialog("Ошибка при чтении массы частицы");
            return;
        }
        
        // Выполнение расчетов в зависимости от выбранной шкалы
        if (radio_k.active) {
            // Кельвин
            if (!validate_double_input(entry_tk.get_text(), out TK)) {
                show_error_dialog("Ошибка при чтении значения температуры в Кельвинах");
                return;
            }
            TC = TK - 273.15;
            TF = 1.8 * TC + 32;
            TR = TC / 1.25;
            TE = 3.0 / 2.0 * TK * k;
        } else if (radio_c.active) {
            // Цельсий
            if (!validate_double_input(entry_tc.get_text(), out TC)) {
                show_error_dialog("Ошибка при чтении значения температуры в Цельсиях");
                return;
            }
            TK = TC + 273.15;
            TF = 1.8 * TC + 32;
            TR = TC / 1.25;
            TE = 3.0 / 2.0 * TK * k;
        } else if (radio_f.active) {
            // Фаренгейт
            if (!validate_double_input(entry_tf.get_text(), out TF)) {
                show_error_dialog("Ошибка при чтении значения температуры в Фаренгейтах");
                return;
            }
            TC = 5.0 / 9.0 * (TF - 32);
            TK = TC + 273.15;
            TR = TC / 1.25;
            TE = 3.0 / 2.0 * TK * k;
        } else if (radio_r.active) {
            // Реомюр
            if (!validate_double_input(entry_tr.get_text(), out TR)) {
                show_error_dialog("Ошибка при чтении значения температуры в Реомюрах");
                return;
            }
            TC = TR * 1.25;
            TK = TC + 273.15;
            TF = 1.8 * TC + 32;
            TE = 3.0 / 2.0 * TK * k;
        } else if (radio_e.active) {
            // Джоуль
            if (!validate_double_input(entry_te.get_text(), out TE)) {
                show_error_dialog("Ошибка при чтении значения энергии в Джоулях");
                return;
            }
            // Формула перевода: E = 3/2 * k * T, следовательно T = 2E/3k
            TK = 2.0 * TE / (3.0 * k);
            TC = TK - 273.15;
            TF = 1.8 * TC + 32;
            TR = TC / 1.25;
        }
        
        // Расчет скорости
        calculate_velocity();
        
        // Отображение результатов
        show_parameters();
    }
    
    // Функция для валидации ввода числа с плавающей точкой
    private bool validate_double_input(string input, out double result) {
        result = 0.0;
        
        // Проверка на пустую строку
        if (input.strip() == "") {
            return false;
        }
        
        // Попытка преобразовать строку в число
        bool success = double.try_parse(input, out result);
        return success;
    }
    
    private void calculate_velocity() {
        // Формула: v = sqrt(8kT/(πm))
        V = Math.sqrt(TK * k * 8 / (Pi * m));
    }
    
    private void show_parameters() {
        entry_tk.set_text("%.2f".printf(TK));
        entry_tc.set_text("%.2f".printf(TC));
        entry_tf.set_text("%.2f".printf(TF));
        entry_tr.set_text("%.2f".printf(TR));
        entry_te.set_text("%.12e".printf(TE));
        entry_v.set_text("%.0f".printf(V));
    }

    private void show_error_dialog(string message) {
        var parent_window = (Gtk.Window)get_active_window();
        var alert = new AlertDialog(message);
        alert.set_detail("Убедитесь, что введено корректное число.\n\nПример формата: 1.38e-23");
        
        // Не используем set_buttons вообще, так как это вызывает ошибку типов
        // По умолчанию будет показана кнопка OK
        alert.set_modal(true);
        alert.set_default_button(0);
        alert.show(parent_window);
    }

    public static int main(string[] args) {
        return new TemperatureConverter().run(args);
    }
}
