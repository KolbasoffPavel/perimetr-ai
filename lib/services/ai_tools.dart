import 'material_calculator.dart';
import '../state/app_state.dart';

/// Системный промпт для ИИ-чата: объясняет роль ассистента и когда
/// пользоваться инструментами вместо простого текстового ответа.
const String assistantSystemPrompt =
    'Ты — встроенный ИИ-ассистент приложения ПЕРИМЕТР для расчёта смет ремонта. '
    'Если пользователь просит добавить помещение, позицию в прайс-лист или строку в смету — '
    'используй соответствующий инструмент, не проси уточнений без необходимости, разумно '
    'предполагай единицы измерения и количество, если это очевидно из контекста. '
    'Если пользователь прикладывает PDF проекта — внимательно изучи документ, определи все '
    'помещения с их размерами (добавь их через add_room, если их ещё нет в проекте), и для '
    'каждого помещения и каждого явно упомянутого или напрашивающегося вида отделочных работ '
    '(обои, покраска, напольное покрытие, плитка, штукатурка) вызови calculate_and_add_material — '
    'он сам посчитает нужное количество материала по формуле и добавит строку в смету. Если в '
    'документе не указана цена материала — оставь pricePerUnit равным 0, пользователь сможет '
    'поправить цену вручную в смете. Если пользователь спрашивает про текущее состояние объекта — '
    'сначала вызови get_project_info, затем ответь на основе полученных данных. Для обычных '
    'вопросов о ремонте отвечай текстом как обычно, без вызова инструментов. После вызова '
    'инструментов обязательно кратко подтверди пользователю, что именно было сделано.';

/// Описания инструментов (function calling) для Anthropic API — позволяют
/// ИИ не просто отвечать текстом, а взаимодействовать с данными проекта.
final List<Map<String, dynamic>> assistantTools = [
  {
    'name': 'add_room',
    'description': 'Добавляет новое помещение в текущий объект с указанными размерами в метрах.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Название помещения, например "Кухня"'},
        'length': {'type': 'number', 'description': 'Длина в метрах'},
        'width': {'type': 'number', 'description': 'Ширина в метрах'},
        'height': {'type': 'number', 'description': 'Высота в метрах, по умолчанию 2.7'},
      },
      'required': ['name', 'length', 'width'],
    },
  },
  {
    'name': 'add_price_item',
    'description': 'Добавляет позицию (работу или материал) в прайс-лист с ценой за единицу измерения.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'unit': {'type': 'string', 'description': 'Единица измерения: м², шт, м.п. и т.п.'},
        'price': {'type': 'number', 'description': 'Цена за единицу в рублях'},
      },
      'required': ['name', 'unit', 'price'],
    },
  },
  {
    'name': 'add_estimate_item',
    'description': 'Добавляет позицию в смету текущего объекта (с уже готовым количеством).',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'unit': {'type': 'string'},
        'quantity': {'type': 'number'},
        'price': {'type': 'number', 'description': 'Цена за единицу в рублях'},
      },
      'required': ['name', 'unit', 'quantity', 'price'],
    },
  },
  {
    'name': 'calculate_and_add_material',
    'description':
        'Считает нужное количество отделочного материала по стандартной формуле (площадь помещения '
        'с учётом типа работ и запаса на подрезку) и сразу добавляет готовую строку в смету. '
        'Категории: wallpaper (обои), paint (краска), flooring (напольное покрытие), tile (плитка), '
        'plaster (штукатурка/шпаклёвка).',
    'input_schema': {
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'enum': ['wallpaper', 'paint', 'flooring', 'tile', 'plaster'],
        },
        'itemName': {'type': 'string', 'description': 'Название строки в смете, например "Обои — Кухня"'},
        'length': {'type': 'number', 'description': 'Длина помещения, м'},
        'width': {'type': 'number', 'description': 'Ширина помещения, м'},
        'height': {'type': 'number', 'description': 'Высота помещения, м (не нужна для flooring и tile)'},
        'wastePercent': {'type': 'number', 'description': 'Запас на подрезку, %, по умолчанию 10'},
        'rollWidth': {'type': 'number', 'description': 'Для wallpaper: ширина рулона, м, по умолчанию 1.06'},
        'rollLength': {'type': 'number', 'description': 'Для wallpaper: длина рулона, м, по умолчанию 10'},
        'coveragePerLiter': {'type': 'number', 'description': 'Для paint: расход, м²/л, по умолчанию 10'},
        'coats': {'type': 'number', 'description': 'Для paint: количество слоёв, по умолчанию 2'},
        'kgPerSqm': {'type': 'number', 'description': 'Для plaster: расход, кг/м², по умолчанию 8'},
        'pricePerUnit': {'type': 'number', 'description': 'Цена за единицу материала, ₽. Если неизвестна — 0.'},
      },
      'required': ['category', 'itemName', 'length', 'width'],
    },
  },
  {
    'name': 'get_project_info',
    'description':
        'Возвращает текущие данные объекта: список помещений, прайс-лист и позиции сметы с итоговой суммой. '
        'Используй перед ответом на вопросы о текущем состоянии проекта.',
    'input_schema': {'type': 'object', 'properties': {}},
  },
];
/// Выполняет вызванный ИИ инструмент над данными приложения и возвращает
/// результат, который отправляется обратно в Anthropic API как tool_result.
Map<String, dynamic> executeAssistantTool(
  String name,
  Map<String, dynamic> input,
  AppState appState,
) {
  try {
    switch (name) {
      case 'add_room':
        final roomName = input['name'] as String;
        appState.addRoom(
          roomName,
          (input['length'] as num).toDouble(),
          (input['width'] as num).toDouble(),
          input['height'] != null ? (input['height'] as num).toDouble() : 2.7,
        );
        return {'success': true, 'message': 'Помещение "$roomName" добавлено в замеры'};

      case 'add_price_item':
        final itemName = input['name'] as String;
        appState.addPriceItem(
          itemName,
          input['unit'] as String,
          (input['price'] as num).toDouble(),
        );
        return {'success': true, 'message': 'Позиция "$itemName" добавлена в прайс-лист'};

      case 'add_estimate_item':
        final itemName = input['name'] as String;
        appState.addEstimateItem(
          itemName,
          input['unit'] as String,
          (input['quantity'] as num).toDouble(),
          (input['price'] as num).toDouble(),
        );
        return {'success': true, 'message': 'Позиция "$itemName" добавлена в смету'};

      case 'calculate_and_add_material':
        final category = input['category'] as String;
        final itemName = input['itemName'] as String;
        final length = (input['length'] as num).toDouble();
        final width = (input['width'] as num).toDouble();
        final height = input['height'] != null ? (input['height'] as num).toDouble() : 2.7;
        final waste = input['wastePercent'] != null ? (input['wastePercent'] as num).toDouble() : 10.0;
        final price = input['pricePerUnit'] != null ? (input['pricePerUnit'] as num).toDouble() : 0.0;

        MaterialResult result;
        switch (category) {
          case 'wallpaper':
            result = MaterialCalculator.wallpaper(
              length: length,
              width: width,
              height: height,
              rollWidth: input['rollWidth'] != null ? (input['rollWidth'] as num).toDouble() : 1.06,
              rollLength: input['rollLength'] != null ? (input['rollLength'] as num).toDouble() : 10,
              wastePercent: waste,
            );
            break;
          case 'paint':
            result = MaterialCalculator.paint(
              areaToPaint: MaterialCalculator.wallArea(length, width, height),
              coveragePerLiter: input['coveragePerLiter'] != null ? (input['coveragePerLiter'] as num).toDouble() : 10,
              coats: input['coats'] != null ? (input['coats'] as num).round() : 2,
            );
            break;
          case 'flooring':
            result = MaterialCalculator.flooring(length: length, width: width, wastePercent: waste);
            break;
          case 'tile':
            result = MaterialCalculator.tile(area: length * width, wastePercent: waste);
            break;
          case 'plaster':
            result = MaterialCalculator.plaster(
              area: MaterialCalculator.wallArea(length, width, height),
              kgPerSqm: input['kgPerSqm'] != null ? (input['kgPerSqm'] as num).toDouble() : 8,
            );
            break;
          default:
            return {'success': false, 'error': 'Неизвестная категория материала: $category'};
        }

        appState.addEstimateItem(itemName, result.unit, result.quantity, price);
        return {
          'success': true,
          'message': 'Добавлено в смету: "$itemName" — ${result.quantity} ${result.unit}',
          'explanation': result.explanation,
        };

      case 'get_project_info':
        final p = appState.activeProject;
        return {
          'projectName': p.name,
          'rooms': p.rooms
              .map((r) => {'name': r.name, 'length': r.length, 'width': r.width, 'height': r.height, 'area': r.area})
              .toList(),
          'priceList': appState.priceList.map((x) => {'name': x.name, 'unit': x.unit, 'price': x.price}).toList(),
          'estimateItems': p.estimateItems
              .map((x) => {'name': x.name, 'unit': x.unit, 'quantity': x.quantity, 'price': x.price, 'total': x.total})
              .toList(),
          'estimateTotal': appState.estimateTotal,
        };

      default:
        return {'success': false, 'error': 'Неизвестный инструмент: $name'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Ошибка выполнения: $e'};
  }
}
