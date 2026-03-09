// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricsCacheAdapter extends TypeAdapter<LyricsCache> {
  @override
  final int typeId = 4;

  @override
  LyricsCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricsCache(
      videoId: fields[0] as String,
      trackName: fields[1] as String?,
      artistName: fields[2] as String?,
      plainLyrics: fields[3] as String?,
      notFound: fields[4] as bool,
      cachedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LyricsCache obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.trackName)
      ..writeByte(2)
      ..write(obj.artistName)
      ..writeByte(3)
      ..write(obj.plainLyrics)
      ..writeByte(4)
      ..write(obj.notFound)
      ..writeByte(5)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
