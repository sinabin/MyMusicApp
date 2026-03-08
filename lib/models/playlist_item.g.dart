// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistItemAdapter extends TypeAdapter<PlaylistItem> {
  @override
  final int typeId = 2;

  @override
  PlaylistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistItem(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      trackVideoIds: (fields[3] as List?)?.cast<String>(),
      thumbnailUrl: fields[4] as String?,
      description: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.trackVideoIds)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
