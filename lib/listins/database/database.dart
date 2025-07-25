import "dart:io";
import "package:pacotes_essenciais/listins/models/listin.dart";
import "package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart"
    show applyWorkaroundToOpenSqlite3OnOldAndroidVersions;

import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:path/path.dart" as path show join;
import "package:path_provider/path_provider.dart";

part 'database.g.dart';

class ListinTable extends Table {
  IntColumn get id => integer().named("id").autoIncrement()();
  TextColumn get name => text().named("name").withLength(min: 4, max: 30)();
  TextColumn get obs => text().named("obs")();
  DateTimeColumn get dateCreate => dateTime().named("dateCreate")();
  DateTimeColumn get dateUpdate => dateTime().named("dateUpdate")();
}

@DriftDatabase(tables: [ListinTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> insertListin(Listin listin) async {
    return await into(listinTable).insert(
      ListinTableCompanion.insert(
        name: listin.name,
        obs: listin.obs,
        dateCreate: listin.dateCreate,
        dateUpdate: listin.dateUpdate,
      ),
    );
  }

  Future<bool> updateListin(Listin listin) async {
    return await update(listinTable).replace(
      ListinTableCompanion(
        id: Value(int.parse(listin.id)),
        name: Value(listin.name),
        obs: Value(listin.obs),
        dateCreate: Value(listin.dateCreate),
        dateUpdate: Value(listin.dateUpdate),
      ),
    );
  }

  Future<List<Listin>> getListins(String? choice) async {
    List<Listin> list = [];
    var query = select(listinTable);
    if (choice != null) {
      if (choice == "Ordenar por nome") {
        query.orderBy([
          (listin) =>
              OrderingTerm(expression: listin.name, mode: OrderingMode.asc),
        ]);
      } else {
        query.orderBy([
          (listin) => OrderingTerm(
            expression: listin.dateUpdate,
            mode: OrderingMode.desc,
          ),
        ]);
      }
    }
    var listinData = await query.get();
    for (ListinTableData row in listinData) {
      list.add(Listin.fromMap(row.toJson()));
    }
    return list;
  }

  Future<int> deleteListin(int id) async {
    return await (delete(listinTable)..where((row) => row.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbfolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbfolder.path, "db.sqlite"));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}
