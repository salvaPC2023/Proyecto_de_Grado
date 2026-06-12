class CreateTechnicianRequest {
  const CreateTechnicianRequest({required this.username, required this.displayName});
  final String username;
  final String displayName;
  Map<String, dynamic> toJson() => {'username': username, 'display_name': displayName};
}

class UpdateTechnicianRequest {
  const UpdateTechnicianRequest({this.username, this.displayName});
  final String? username;
  final String? displayName;
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (username != null) m['username'] = username;
    if (displayName != null) m['display_name'] = displayName;
    return m;
  }
}
