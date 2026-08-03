import 'package:flutter/foundation.dart';

class Project {
    final String id;
    String name;
    Project({required this.id, required this.name});
}

class AppState extends ChangeNotifier {
    bool loaded = false;
    final List<Project> projects = [Project(id: '1', name: 'Novyi obiekt')];
    String activeProjectId = '1';

    AppState() {
          _init();
    }

    Future<void> _init() async {
          loaded = true;
          notifyListeners();
    }

    Project get activeProject =>
            projects.firstWhere((p) => p.id == activeProjectId, orElse: () => projects.first);

    void setActiveProject(String id) {
          activeProjectId = id;
          notifyListeners();
    }

    void addProject(String name) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          projects.add(Project(id: id, name: name));
          activeProjectId = id;
          notifyListeners();
    }
}
