import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

// Url WebService
const String request = 'https://hudson-project-esig.herokuapp.com/cliente';

// Headers
const Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

// Enums PopMenu
enum WhyFarther { All, Actives, Completed }

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  List _toDoListAux = [];
  Map<String, dynamic> _lastRemove;
  int _itemRemovePos;

  var _selection;

  TextEditingController _tarefaController = new TextEditingController();

  /*
  *  GetRequest -> faz uma chamada assincrona ao servidor
  * */
  Future<Null> _getRequestData() async {
    http.Response response = await http.get(request);
    setState(() {
      this._toDoList = json.decode(response.body);
    });
  }

  /*
  *  GetRequest -> faz uma chamada assincrona ao servidor (Não seta o estado)
  * */
  Future<Null> _getRequestDataN() async {
    http.Response response = await http.get(request);
    this._toDoList = json.decode(response.body);
  }

  /*
  *   PostRequest -> Faz uma chamada assincrona ao servidor
  *   Esta requisição também pode ser usada para Updade do objeto no banco
  * */
  void _postRequestData(String name, bool status, int id) async {
    Map<String, dynamic> body = Map();

    if (id != null) {
      body['id'] = id;
      body['name'] = name;
      body['status'] = status;
    } else {
      body['name'] = name;
      body['status'] = status;
    }

    http.Response response =
        await http.post(request, headers: headers, body: json.encode(body));
    print(response.statusCode);
    print(response.body);

    // Novo Get redesenha a tela...
    this._getRequestData();

    this._tarefaController.text = '';
  }

  /*
  *  DeleteRequest -> Faz uma chamada assincrona ao servidor
  * */
  Future<Null> _deleteRequestData(int id) async {
    http.Response response =
        await http.delete(request + '/${id}', headers: headers);

    // Nova requisição get Redesenha a tela ...
    this._getRequestData();
  }

  /*
  *   ListByCompleted (completed -> status = true)
  * */
  void listByCompleted() {
    List aux = [];
    this._getRequestDataN();
    for (int i = 0; i < this._toDoList.length; i++) {
      if (this._toDoList[i]['status'] == true) {
        aux.add(this._toDoList[i]);
      }
    }
    setState(() {
      this._toDoList = aux;
    });
  }

  void listAll(){
    this._getRequestData();
  }

  /*
  *   ListByCompleted (completed -> status = true)
  * */
  void listByActives() {
    List aux = [];
    this._getRequestDataN();
    for (int i = 0; i < this._toDoList.length; i++) {
      if (this._toDoList[i]['status'] == false) {
        aux.add(this._toDoList[i]);
      }
    }
    setState(() {
      this._toDoList = aux;
    });
  }

  /*
  *   DeleteALL
  * */
  void deleteAll(){
    for(var a in this._toDoList){
      if(a['status'] == true){
        this._deleteRequestData(a['id']);
      }
    }
    setState(() {
      this._getRequestData();
    });
  }

  /*
  *   Função invocada na inicialização da Aplicação.
  *   análog ao onStart() -> android nativo.
  *   Recebe os dados do banco antes da inicialização.
  *
  * */
  @override
  void initState() {
    super.initState();
    this._getRequestData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.delete_forever,
        ),
        backgroundColor: Colors.deepOrange,
        onPressed: (){
          deleteAll();
        },
      ),
      appBar: AppBar(
        title: Text('To do List'),
        backgroundColor: Colors.deepOrangeAccent,
        actions: <Widget>[
          PopupMenuButton<WhyFarther>(
            onSelected: (WhyFarther result) {
              setState(() {
                _selection = result;
                print(_selection);
                if(result == WhyFarther.Completed){
                  this.listByCompleted();
                }else if (result == WhyFarther.Actives){
                  this.listByActives();
                }else{
                  this.listAll();
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<WhyFarther>>[
                  const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.All,
                    child: Text(
                      'All',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                  const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.Actives,
                    child: Text(
                      'Actives',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                  const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.Completed,
                    child: Text(
                      'Completed',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  )
                ],
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 5, 17.0, 0.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'New Task',
                      labelStyle: TextStyle(color: Colors.deepOrangeAccent),
                    ),
                    controller: this._tarefaController,
                  ),
                ),
                RaisedButton(
                  color: Colors.deepOrangeAccent,
                  child: Text('Add'),
                  textColor: Colors.white,
                  onPressed: () {
                    this._postRequestData(
                        this._tarefaController.text, false, null);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: this._refresh,
                child: ListView.builder(
                    itemBuilder: this.buildItem,
                    padding: EdgeInsets.only(top: 10),
                    itemCount: this._toDoList.length)),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    // Dismissible -> Permite arrastar um layout...
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete_forever,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['name']),
        value: _toDoList[index]['status'],
        activeColor: Colors.deepOrange,
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['status'] ? Icons.check : Icons.error),
        ),
        onChanged: (bool) {
          print(bool);
          setState(() {
            _toDoList[index]['status'] = bool;
            this._postRequestData(_toDoList[index]['name'],
                _toDoList[index]['status'], _toDoList[index]['id']);
          });
        },
      ),
      onDismissed: (derection) {
        setState(() {
          this._lastRemove = Map.from(_toDoList[index]);
          this._itemRemovePos = index;
          this._toDoList.removeAt(index);

          // Pega o item selecionado e deleta do Banco de dados
          this._deleteRequestData(this._lastRemove['id']);

          final SnackBar snackBar = SnackBar(
            content: Text("Tarefa ${_lastRemove['name']} Removida"),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    this._postRequestData(_lastRemove['name'],
                        _lastRemove['status'], _lastRemove['id']);
                  });
                }),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar(); // ADICIONE ESTE COMANDO
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  /*
  *  Refresh List Itens
  * */
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1)); // Força uma espera
    setState(() {
      this._getRequestData();
    });
  }
}
