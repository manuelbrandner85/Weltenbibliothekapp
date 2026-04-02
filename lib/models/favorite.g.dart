// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteAdapter extends TypeAdapter<Favorite> {
  @override
  final int typeId = 0;

  @override
  Favorite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Favorite(
      id: fields[0] as String,
      type: fields[1] as FavoriteType,
      title: fields[2] as String,
      description: fields[3] as String?,
      url: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      metadata: (fields[6] as Map?)?.cast<String, dynamic>(),
      tags: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Favorite obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.url)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.metadata)
      ..writeByte(7)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FavoriteTypeAdapter extends TypeAdapter<FavoriteType> {
  @override
  final int typeId = 1;

  @override
  FavoriteType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FavoriteType.research;
      case 1:
        return FavoriteType.narrative;
      case 2:
        return FavoriteType.pdf;
      case 3:
        return FavoriteType.image;
      case 4:
        return FavoriteType.video;
      case 5:
        return FavoriteType.telegram;
      case 6:
        return FavoriteType.source;
      default:
        return FavoriteType.research;
    }
  }

  @override
  void write(BinaryWriter writer, FavoriteType obj) {
    switch (obj) {
      case FavoriteType.research:
        writer.writeByte(0);
        break;
      case FavoriteType.narrative:
        writer.writeByte(1);
        break;
      case FavoriteType.pdf:
        writer.writeByte(2);
        break;
      case FavoriteType.image:
        writer.writeByte(3);
        break;
      case FavoriteType.video:
        writer.writeByte(4);
        break;
      case FavoriteType.telegram:
        writer.writeByte(5);
        break;
      case FavoriteType.source:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
