class NotificationPreferences {
  final bool staleCvEnabled;
  final bool cvViewsEnabled;
  final bool aiTipsEnabled;

  const NotificationPreferences({
    this.staleCvEnabled = true,
    this.cvViewsEnabled = true,
    this.aiTipsEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        staleCvEnabled: json['staleCvEnabled'] as bool? ?? true,
        cvViewsEnabled: json['cvViewsEnabled'] as bool? ?? true,
        aiTipsEnabled: json['aiTipsEnabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'staleCvEnabled': staleCvEnabled,
        'cvViewsEnabled': cvViewsEnabled,
        'aiTipsEnabled': aiTipsEnabled,
      };

  NotificationPreferences copyWith(
          {bool? staleCvEnabled, bool? cvViewsEnabled, bool? aiTipsEnabled}) =>
      NotificationPreferences(
        staleCvEnabled: staleCvEnabled ?? this.staleCvEnabled,
        cvViewsEnabled: cvViewsEnabled ?? this.cvViewsEnabled,
        aiTipsEnabled: aiTipsEnabled ?? this.aiTipsEnabled,
      );
}
