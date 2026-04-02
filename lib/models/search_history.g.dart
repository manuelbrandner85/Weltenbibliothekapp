// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SearchHistoryEntryAdapter extends TypeAdapter<SearchHistoryEntry> {
  @override
  final int typeId = 2;

  @override
  SearchHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SearchHistoryEntry(
      id: fields[0] as String,
      query: fields[1] as String,
      timestamp: fields[2] as DateTime,
      resultCount: fields[3] as int,
      summary: fields[4] as String?,
      tags: (fields[5] as List?)?.cast<String>(),
      metadata: (fields[6] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SearchHistoryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.query)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.resultCount)
      ..writeByte(4)
      ..write(obj.summary)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
