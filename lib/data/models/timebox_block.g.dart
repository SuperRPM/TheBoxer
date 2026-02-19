// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timebox_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeboxBlockAdapter extends TypeAdapter<TimeboxBlock> {
  @override
  final int typeId = 0;

  @override
  TimeboxBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeboxBlock(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      startMinute: fields[2] as int,
      endMinute: fields[3] as int,
      title: fields[4] as String,
      description: fields[5] as String?,
      categoryId: fields[6] as String?,
      routineId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeboxBlock obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.startMinute)
      ..writeByte(3)
      ..write(obj.endMinute)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.routineId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeboxBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
