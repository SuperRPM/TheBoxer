// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyPlanAdapter extends TypeAdapter<WeeklyPlan> {
  @override
  final int typeId = 3;

  @override
  WeeklyPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyPlan(
      id: fields[0] as String,
      weekStartDate: fields[1] as DateTime,
      content: fields[2] as String,
      goals: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyPlan obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekStartDate)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.goals);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
