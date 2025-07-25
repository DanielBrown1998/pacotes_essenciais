import 'package:flutter/material.dart';
import 'package:pacotes_essenciais/authentication/models/mock_user.dart';
import 'package:pacotes_essenciais/listins/database/database.dart';
import 'package:pacotes_essenciais/listins/screens/widgets/home_drawer.dart';
import 'package:pacotes_essenciais/listins/screens/widgets/home_listin_item.dart';
import '../models/listin.dart';
import 'widgets/listin_add_edit_modal.dart';
import 'widgets/listin_options_modal.dart';

class HomeScreen extends StatefulWidget {
  final MockUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];
  late AppDatabase _appDatabase;

  String byName = "Ordenar por nome";
  String byUpdateData = "Ordenar por Data de alteracao";
  String? choice;
  @override
  void initState() {
    _appDatabase = AppDatabase();
    refresh();
    choice = byName;
    super.initState();
  }

  @override
  void dispose() {
    _appDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(user: widget.user),
      appBar: AppBar(
        title: const Text("Minhas listas"),
        centerTitle: false,
        actionsPadding: EdgeInsets.symmetric(horizontal: 16),
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: DropdownButton(
              isExpanded: true,
              value: choice,
              icon: Icon(Icons.filter),
              menuWidth: MediaQuery.of(context).size.width / 2,
              items: [
                DropdownMenuItem(
                  value: byName,
                  child: Text(byName, style: TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: byUpdateData,
                  child: Text(byUpdateData, style: TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value != null) choice = value;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddModal();
        },
        child: const Icon(Icons.add),
      ),
      body:
          (listListins.isEmpty)
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset("assets/bag.png"),
                    const SizedBox(height: 32),
                    const Text(
                      "Nenhuma lista ainda.\nVamos criar a primeira?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () {
                  return refresh();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  child: ListView(
                    children: List.generate(listListins.length, (index) {
                      Listin listin = listListins[index];
                      return HomeListinItem(
                        listin: listin,
                        showOptionModal: showOptionModal,
                      );
                    }),
                  ),
                ),
              ),
    );
  }

  showAddModal({Listin? listin}) {
    showAddEditListinModal(
      context: context,
      onRefresh: refresh,
      model: listin,
      appDatabase: _appDatabase,
    ).then((value) {
      if (value != null && value) {
        refresh();
      }
    });
  }

  showOptionModal(Listin listin) {
    showListinOptionsModal(
      context: context,
      listin: listin,
      onRemove: remove,
    ).then((value) {
      if (value != null && value) {
        showAddModal(listin: listin);
      }
    });
  }

  refresh() async {
    // Basta alimentar essa variável com Listins que, quando o método for
    // chamado, a tela sera reconstruída com os itens.
    List<Listin> listaListins = await _appDatabase.getListins(choice);

    setState(() {
      listListins = listaListins;
    });
  }

  void remove(Listin model) async {
    await _appDatabase.deleteListin(int.parse(model.id));
    refresh();
  }
}
