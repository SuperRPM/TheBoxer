// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brain_dump_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrainDumpItemAdapter extends TypeAdapter<BrainDumpItem> {
  @override
  final int typeId = 4;

  @override
  BrainDumpItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrainDumpItem(
      id: fields[0] as String,
      content: fields[1] as String,
      isChecked: fields[2] as bool,
      createdAt: fields[3] as DateTime,
      isStarred: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BrainDumpItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.isChecked)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isStarred);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrainDumpItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
