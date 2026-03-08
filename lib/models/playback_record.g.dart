// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaybackRecordAdapter extends TypeAdapter<PlaybackRecord> {
  @override
  final int typeId = 3;

  @override
  PlaybackRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackRecord(
      videoId: fields[0] as String,
      playedAt: fields[1] as DateTime,
      durationPlayedMs: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.playedAt)
      ..writeByte(2)
      ..write(obj.durationPlayedMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
