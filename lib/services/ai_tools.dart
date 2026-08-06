import '../state/app_state.dart';

/// Системный промпт для ИИ-чата: объясняет роль ассистента и когда
/// пользоваться инструментами вместо простого текстового ответа.
const String assistantSystemPrompt =
    'Ты — встроенный ИИ-ассистент приложения ПЕРИМЕТР для расчёта смет ремонта. '
    'Если пользователь просит добавить помещение, позицию в прайс-лист или строку в смету — '
    'используй соответствующий инструмент, не проси уточнений без необходимости, разумно '
    'предполагай единицы измерения и количество, если это очевидно из контекста. '
    'Если пользователь спрашивает про текущее состояние объекта (что уже есть в смете, '
    'сколько стоит и т.п.) — сначала вызови get_project_info, затем ответь на основе '
    'полученных данных. Для обычных вопросов о ремонте отвечай текстом как обычно, без '
    'вызова инструментов. После вызова инструмента обязательно кратко подтверди пользователю, '
    'что именно было сделано.';

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
    'description': 'Добавляет позицию в смету текущего объекта (с количеством).',
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
