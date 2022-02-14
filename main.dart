import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: WikipediaExplorer()));

final txtEntrada = TextEditingController();

class WikipediaExplorer extends StatefulWidget {
  const WikipediaExplorer({Key? key}) : super(key: key);

  @override
  _WikipediaExplorerState createState() => _WikipediaExplorerState();
}

class _WikipediaExplorerState extends State<WikipediaExplorer> {
  final _controller = Completer<WebViewController>();
  late WebViewController controler;
  final Set<String> _favorites = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: const Color.fromARGB(250, 170, 170, 170),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Container(
                child: NavigationControls(_controller.future),
              ),
            ),
            Container(child: Expanded(child: textfieldBuscar())),
            Padding(
              padding: const EdgeInsets.only(left: 3.5),
              child:
                  Container(child: Menu(_controller.future, () => _favorites)),
            ),
          ],
        ),
        floatingActionButton: _bookmarkButton(),
        body: Column(children: [
          Row(),
          Expanded(
            child: WebView(
              initialUrl: "https://amazon.es",
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
                controler = webViewController;
              },
            ),
          ),
        ]));
  }

  _bookmarkButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (controller.hasData) {
          return Container(
            child: FloatingActionButton(
              onPressed: () async {
                var url = await controller.data?.currentUrl();
                _favorites.add(url!);
                // ignore: deprecated_member_use
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('$url guardado.')),
                );
              },
              child: const Icon(
                Icons.favorite,
                size: 35.0,
              ),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          );
        }
        return Container();
      },
    );
  }

  textfieldBuscar() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: SizedBox(
            width: 250.0,
            child: Container(
              child: TextField(
                  cursorWidth: 2.0,
                  cursorHeight: 5.0,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                          onPressed: () =>
                              _launchURL(txtEntrada.text, controler),
                          color: Colors.black,
                          icon: const Icon(Icons.search)),
                      hoverColor: Colors.black,
                      focusColor: Colors.black,
                      filled: true,
                      hintText: '',
                      hintStyle: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      fillColor: const Color.fromARGB(250, 170, 170, 170)),
                  style: const TextStyle(
                    height: 35.0,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.left,
                  enableIMEPersonalizedLearning: true,
                  controller: txtEntrada),
            ),
          ),
        ),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  Menu(this._webViewControllerFuture, this.favoritesAccessor);
  final Future<WebViewController> _webViewControllerFuture;
  final Function favoritesAccessor;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (!controller.hasData) return Container();
        return Container(
            child: PopupMenuButton<String>(
                onSelected: (String value) async {
                  if (value == 'See Favorites') {
                    var newUrl = await Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                      return FavoritesPage(favoritesAccessor());
                    }));
                    Scaffold.of(context).removeCurrentSnackBar();
                    if (newUrl != null) controller.data?.loadUrl(newUrl);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(
                        value: 'See Favorites',
                        child: Text('Favoritos'),
                      ),
                    ],
                color: Colors.white),
            color: const Color.fromARGB(250, 80, 80, 80));
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  FavoritesPage(this.favorites);
  final Set<String> favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        child: ListView(
            children: favorites
                .map((url) => ListTile(
                    title: Text(url), onTap: () => Navigator.pop(context, url)))
                .toList()),
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Container(
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 25.0,
                  ),
                  onPressed: !webViewReady
                      ? null
                      : () => navigate(context, controller!, goBack: true),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                  size: 25.0,
                ),
                onPressed: !webViewReady
                    ? null
                    : () => navigate(context, controller!, goBack: false),
              ),
            ],
          ),
        );
      },
    );
  }

  navigate(BuildContext context, WebViewController controller,
      {bool goBack: false}) async {
    bool canNavigate =
        goBack ? await controller.canGoBack() : await controller.canGoForward();
    if (canNavigate) {
      goBack ? controller.goBack() : controller.goForward();
    } else {
      // ignore: deprecated_member_use
      Scaffold.of(context).showSnackBar(
        const SnackBar(content: Text("No hay historial disponible")),
      );
    }
  }
}

_launchURL(String enlace, WebViewController controller) async {
  var url = enlace;
  if (!url.startsWith('https://www.')) {
    if (!url.endsWith(".com") &&
        await canLaunch("https://www." + url + ".com")) {
      controller.loadUrl("https://www." + url + ".com");
    } else if (!url.endsWith(".es") &&
        await canLaunch("https://www." + url + ".es")) {
      controller.loadUrl("https://www." + url + ".es");
    } else {
      throw 'Could not launch $url';
    }
  } else {
    await controller.loadUrl(url);
  }
}
