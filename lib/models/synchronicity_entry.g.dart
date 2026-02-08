// GENERATED CODE
part of 'synchronicity_entry.dart';

class SynchronicityEntryAdapter extends TypeAdapter<SynchronicityEntry> {
  @override
  final int typeId = 11;

  @override
  SynchronicityEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SynchronicityEntry(
      timestamp: fields[0] as DateTime,
      description: fields[1] as String,
      pattern: fields[2] as String?,
      tags: (fields[3] as List?)?.cast<String>(),
      significance: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SynchronicityEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.pattern)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.significance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SynchronicityEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
