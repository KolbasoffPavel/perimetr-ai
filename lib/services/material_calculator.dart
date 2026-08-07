/// Результат расчёта материала: сколько нужно и в каких единицах,
/// плюс человекочитаемое пояснение расчёта.
class MaterialResult {
final double quantity;
final String unit;
final String explanation;
MaterialResult({required this.quantity, required this.unit, required this.explanation});
}

/// Стандартные формулы расчёта расхода отделочных материалов по площади
/// помещения. Используются и в экране калькулятора, и как инструмент ИИ —
/// единая логика в одном месте.
class MaterialCalculator {
/// Периметр стен по длине и ширине помещения, без вычета проёмов.
static double wallPerimeter(double length, double width) => (length + width) * 2;

/// Площадь стен (периметр × высота).
static double wallArea(double length, double width, double height) =>
wallPerimeter(length, width) * height;

/// Обои: количество рулонов.
static MaterialResult wallpaper({
required double length,
required double width,
required double height,
double rollWidth = 1.06,
double rollLength = 10,
double wastePercent = 10,
}) {
final area = wallArea(length, width, height) * (1 + wastePercent / 100);
final areaPerRoll = rollWidth * rollLength;
final rolls = (area / areaPerRoll).ceilToDouble();
return MaterialResult(
quantity: rolls,
unit: 'рулон',
explanation:
'Площадь стен ${wallArea(length, width, height).toStringAsFixed(1)} м² + запас ${wastePercent.toStringAsFixed(0)}% '
'= ${area.toStringAsFixed(1)} м², рулон ${rollWidth}×${rollLength} м даёт ${areaPerRoll.toStringAsFixed(1)} м²',
);
}

/// Краска: сколько литров с учётом расхода на м² и числа слоёв.
static MaterialResult paint({
required double areaToPaint,
double coveragePerLiter = 10,
int coats = 2,
}) {
final liters = (areaToPaint * coats / coveragePerLiter);
return MaterialResult(
quantity: double.parse(liters.toStringAsFixed(1)),
unit: 'л',
explanation:
'Площадь ${areaToPaint.toStringAsFixed(1)} м² × $coats слоя ÷ ${coveragePerLiter.toStringAsFixed(0)} м²/л',
);
}
/// Напольное покрытие (ламинат, линолеум, паркет): площадь с запасом.
static MaterialResult flooring({
required double length,
required double width,
double wastePercent = 10,
}) {
final floorArea = length * width;
final total = floorArea * (1 + wastePercent / 100);
return MaterialResult(
quantity: double.parse(total.toStringAsFixed(2)),
unit: 'м²',
explanation:
'Площадь пола ${floorArea.toStringAsFixed(1)} м² + запас на подрезку ${wastePercent.toStringAsFixed(0)}%',
);
}

/// Плитка (пол или стены) — площадь с запасом на подрезку.
static MaterialResult tile({
required double area,
double wastePercent = 10,
}) {
final total = area * (1 + wastePercent / 100);
return MaterialResult(
quantity: double.parse(total.toStringAsFixed(2)),
unit: 'м²',
explanation: 'Площадь ${area.toStringAsFixed(1)} м² + запас на подрезку ${wastePercent.toStringAsFixed(0)}%',
);
}

/// Штукатурка/шпаклёвка — расход в кг по площади и норме кг/м².
static MaterialResult plaster({
required double area,
double kgPerSqm = 8,
}) {
final kg = area * kgPerSqm;
return MaterialResult(
quantity: double.parse(kg.toStringAsFixed(1)),
unit: 'кг',
explanation: 'Площадь ${area.toStringAsFixed(1)} м² × ${kgPerSqm.toStringAsFixed(1)} кг/м²',
);
}
}
