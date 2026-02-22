import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/brain_dump_item.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/models/weekly_plan.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 어댑터 등록
  Hive.registerAdapter(TimeboxBlockAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(WeeklyPlanAdapter());
  Hive.registerAdapter(BrainDumpItemAdapter());

  // Box 오픈
  await Hive.openBox<TimeboxBlock>(AppConstants.timeboxBoxName);
  await Hive.openBox<Category>(AppConstants.categoryBoxName);
  await Hive.openBox<Routine>(AppConstants.routineBoxName);
  await Hive.openBox<WeeklyPlan>(AppConstants.weeklyPlanBoxName);
  await Hive.openBox<BrainDumpItem>(AppConstants.brainDumpBoxName);
  await Hive.openBox<dynamic>(AppConstants.settingsBoxName);

  runApp(const ProviderScope(child: TimeboxPlannerApp()));
}
