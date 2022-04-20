import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:iptvlite/iptv.dart';
/*import 'package:iptvlite/dog.dart';*/

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, 'IPTV.db');

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(path, onCreate: _onCreate, version: 1);
  }

  Future<Database> initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, 'IPTV.db');

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(path, onCreate: _onCreate, version: 2);
  }

  // When the database is first created, create a table to store breeds
  // and a table to store dogs.
  Future<void> _onCreate(Database db, int version) async {
    // Run the CREATE {bp} TABLE statement on the database.
    await db.execute(
      'CREATE TABLE IPTV(name TEXT NOT NULL UNIQUE, url TEXT)',
    );
  }

  // Define a function that inserts breeds into the database
  Future<void> insertData(IPTV iptv) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'IPTV',
      iptv.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
   Future<void> insertDatanotreplace(IPTV iptv) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'IPTV',
      iptv.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  Future close() async {
    final db = await _databaseService.database;
    await db.close();
  }

  // A method that retrieves all the bps from the bps table.
  Future<List<IPTV>> showAll() async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Query the table for all the bps.
    final List<Map<String, dynamic>> maps =
        await db.query('IPTV', orderBy: "name ASC");

    // Convert the List<Map<String, dynamic> into a List<Breed>.
    return List.generate(maps.length, (index) => IPTV.fromMap(maps[index]));
  }

  // A method that deletes a breed data from the breeds table.
  Future<void> delete(String name) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Remove the Breed from the database.
    await db.delete(
      'IPTV',
      // Use a `where` clause to delete a specific breed.
      where: 'name = ?',
      // Pass the Breed's id as a whereArg to prevent SQL injection.
      whereArgs: [name],
    );
  }

  Future<void> clearall() async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Remove the Breed from the database.
    await db.delete(
      'IPTV',
    );
  }

  Future<String> export() async {
    List<List<dynamic>> row = [];
    String csv;
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Query the table for all the bps.
    final List<Map<String, dynamic>> maps =
        await db.query('IPTV', orderBy: "name ASC");
    var all = List.generate(maps.length, (index) => IPTV.fromMap(maps[index]));
    row.add(["Name", "Url"]);
    all.forEach((element) {
      row.add([element.name, element.url]);
    });
    csv = const ListToCsvConverter().convert(row);
    return csv;
  }
}
