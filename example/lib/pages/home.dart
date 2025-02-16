import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  @override
  void initState() {
    TrayManager.instance.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    TrayManager.instance.removeListener(this);
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: Text('destroy'),
              onTap: () {
                TrayManager.instance.destroy();
              },
            ),
            PreferenceListItem(
              title: Text('setIcon'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                      child: Text('Default'),
                      onPressed: () async {
                        await TrayManager.instance.setIcon(
                          Platform.isWindows
                              ? 'images/tray_icon.ico'
                              : 'images/tray_icon.png',
                        );
                      }),
                  CupertinoButton(
                    child: Text('Original'),
                    onPressed: () async {
                      await TrayManager.instance.setIcon(
                        Platform.isWindows
                            ? 'images/tray_icon_original.ico'
                            : 'images/tray_icon_original.png',
                      );
                    },
                  ),
                ],
              ),
              onTap: () async {
                await TrayManager.instance.setIcon(
                  Platform.isWindows
                      ? 'images/tray_icon.ico'
                      : 'images/tray_icon.png',
                );
              },
            ),
            PreferenceListItem(
              title: Text('setToolTip'),
              onTap: () async {
                await TrayManager.instance.setToolTip('tray_manager');
              },
            ),
            PreferenceListItem(
              title: Text('setContextMenu'),
              onTap: () async {
                List<MenuItem> menuItems = [
                  MenuItem(title: 'Undo'),
                  MenuItem(title: 'Redo'),
                  MenuItem.separator,
                  MenuItem(title: 'Cut'),
                  MenuItem(title: 'Copy'),
                  MenuItem(title: 'Paste'),
                  MenuItem.separator,
                  MenuItem(title: 'Find', isEnabled: false),
                  MenuItem(title: 'Replace'),
                ];
                await TrayManager.instance.setContextMenu(menuItems);
              },
            ),
            PreferenceListItem(
              title: Text('popUpContextMenu'),
              onTap: () async {
                await TrayManager.instance.popUpContextMenu();
              },
            ),
            PreferenceListItem(
              title: Text('getBounds'),
              onTap: () async {
                Rect bounds = await TrayManager.instance.getBounds();
                Size size = bounds.size;
                Offset origin = bounds.topLeft;
                BotToast.showText(
                  text: '${size.toString()}\n${origin.toString()}',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: _buildBody(context),
    );
  }

  @override
  void onTrayIconMouseUp() {
    TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    print(TrayManager.instance.getBounds());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    print(menuItem.toJson());
    BotToast.showText(
      text: '${menuItem.toJson()}',
    );
  }
}
