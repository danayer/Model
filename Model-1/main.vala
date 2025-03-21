using Gtk;

public class OrbitalCalculator : Gtk.Application {
    // Константы - такие же, как в оригинале
    private const double M = 5.976e24;    // Масса Земли в кг
    private const double G = 6.672e-11;   // Гравитационная постоянная в H*м²/кг²
    private const double R = 6371030.0;   // Радиус Земли в метрах
    
    // Элементы интерфейса
    private Entry height_entry;
    private Label velocity_label;
    
    public OrbitalCalculator() {
        // Исправлено: FLAGS_NONE заменено на DEFAULT_FLAGS
        Object(application_id: "com.example.orbitalcalculator", flags: ApplicationFlags.DEFAULT_FLAGS);
    }

    protected override void activate() {
        var window = new ApplicationWindow(this) {
            title = "Калькулятор орбитальной скорости",
            default_width = 400,
            default_height = 300,
            resizable = false
        };
        
        var main_box = new Box(Orientation.VERTICAL, 10) {
            margin_start = 20,
            margin_end = 20,
            margin_top = 20,
            margin_bottom = 20
        };
        
        // Отображение констант
        var mass_label = new Label("Масса Земли: " + M.to_string() + " кг");
        mass_label.halign = Align.START;
        
        var g_label = new Label("Гравитационная постоянная: " + G.to_string() + " H*м²/кг²");
        g_label.halign = Align.START;
        
        var radius_label = new Label("Радиус Земли: " + R.to_string() + " м");
        radius_label.halign = Align.START;
        
        // Ввод высоты
        var height_box = new Box(Orientation.HORIZONTAL, 10);
        var height_label = new Label("Высота (метры):");
        height_entry = new Entry();
        height_box.append(height_label);
        height_box.append(height_entry);
        
        // Кнопка расчета
        var calculate_button = new Button.with_label("Рассчитать скорость");
        
        // Отображение результатов
        var result_box = new Box(Orientation.HORIZONTAL, 10);
        var result_label = new Label("Скорость:");
        velocity_label = new Label("0");
        result_box.append(result_label);
        result_box.append(velocity_label);
        
        // Добавление всех виджетов в основной контейнер
        main_box.append(mass_label);
        main_box.append(g_label);
        main_box.append(radius_label);
        main_box.append(new Separator(Orientation.HORIZONTAL));
        main_box.append(height_box);
        main_box.append(calculate_button);
        main_box.append(result_box);
        
        // Подключение сигналов
        calculate_button.clicked.connect(calculate_velocity);
        height_entry.changed.connect(validate_height);
        
        window.set_child(main_box);
        window.present();
    }
    
    // Добавляем атрибут [CCode], чтобы указать, что не используем отправителя сигнала
    [CCode (instance_pos = -1)]
    private void validate_height() {
        double h;
        if (double.try_parse(height_entry.text, out h)) {
            if (h < 0) {
                height_entry.text = "0";
            }
        }
    }
    
    // Добавляем атрибут [CCode], чтобы указать, что не используем отправителя сигнала
    [CCode (instance_pos = -1)]
    private void calculate_velocity() {
        double h;
        if (double.try_parse(height_entry.text, out h)) {
            if (h < 0) {
                h = 0;
                height_entry.text = "0";
            }
            
            // Расчет орбитальной скорости по той же формуле, что и в оригинале
            double v = Math.sqrt(M * G / (R + h));
            v = Math.round(v); // Округление до целого числа как в оригинале
            velocity_label.label = v.to_string() + " м/с";
        }
    }
    
    public static int main(string[] args) {
        return new OrbitalCalculator().run(args);
    }
}
