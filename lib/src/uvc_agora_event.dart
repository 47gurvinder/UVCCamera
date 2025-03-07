import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';


@immutable
class UvcAgoraEvent extends Equatable {
  final String event;
  final Map<String, dynamic>? data;
  final int? uid;

  const UvcAgoraEvent({
    required this.event,
    required this.data,
    required this.uid,
  });

  factory UvcAgoraEvent.fromMap(Map<dynamic, dynamic> map) {
    final data = (map['data'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
    );
    return UvcAgoraEvent(
        event: map['event'],
        uid: map['uid'] as int?,
        data: data

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'data': data,
      'uid': uid,
    };
  }

  @override
  List<Object?> get props =>
      [
        event,
        data,
        uid,
      ];
}
