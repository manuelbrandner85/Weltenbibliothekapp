// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consciousness_entry.dart';

class ConsciousnessEntryAdapter extends TypeAdapter<ConsciousnessEntry> {
  @override
  final int typeId = 10;

  @override
  ConsciousnessEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsciousnessEntry(
      timestamp: fields[0] as DateTime,
      activityType: fields[1] as String,
      duration: fields[2] as int,
      moodBefore: fields[3] as int,
      moodAfter: fields[4] as int,
      notes: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConsciousnessEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.activityType)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.moodBefore)
      ..writeByte(4)
      ..write(obj.moodAfter)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsciousnessEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
