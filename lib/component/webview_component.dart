import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'dart:io';
import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';
// import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as pdfToHtml;
// import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../component/global_dialog.dart';

class WebViewComponent extends StatefulWidget {
  final String initialUrl;
  final String? localStorageData;
  const WebViewComponent({
    Key? key,
    required this.initialUrl,
    this.localStorageData,
  }) : super(key: key);

  @override
  State<WebViewComponent> createState() => WebViewComponentState();
}

class WebViewComponentState extends State<WebViewComponent> {
  void reloadWebView() {
    _webViewController?.reload();
  }

  InAppWebViewController? _webViewController;

  BuildContext? _dialogContext;

  @override
  Widget build(BuildContext context) {
    // initialUrl为空或null时处理
    if (widget.initialUrl.isEmpty) {
      return const Center(child: Text('未指定页面'));
    }
    return Stack(
      children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            needInitialFocus: true,
            // transparentBackground: true,
            // useWideViewPort: true,
            // loadWithOverviewMode: true,
            // textZoom: 16,
          ),
          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _setupJavaScriptHandler(controller);
            print('WebView已创建');
          },
          onCreateWindow: (controller, request) {
            // 直接阻止默认弹窗行为（因为我们将用JS处理器控制）
            return Future.value(false);
          },
          onLoadStart: (controller, url) {
            print('开始加载: ${url?.toString()}');
          },
          onLoadStop: (controller, url) async {
            print('加载完成: ${url?.toString()}');
            _injectPrintInterceptor(controller);
            if (widget.localStorageData != null) {
              _setLocalStorage(controller, widget.localStorageData!);
            }
          },
          onLoadError: (controller, url, code, message) {
            print('加载错误: $code - $message');
            print('URL: ${url?.toString()}');
          },
          onConsoleMessage: (controller, consoleMessage) {
            _handleConsoleMessage(consoleMessage);
          },
        ),
      ],
    );
  }

  // initialUrl修改时也就是切换页面了
  @override
  void didUpdateWidget(covariant WebViewComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有controller已初始化且initialUrl有效时才loadUrl
    if (_webViewController != null &&
        widget.initialUrl.isNotEmpty &&
        oldWidget.initialUrl != widget.initialUrl) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      );
      if (widget.localStorageData != null) {
        _setLocalStorage(_webViewController!, widget.localStorageData!);
      }
    }
    // if (widget.initialUrl.isEmpty) {
    //   _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri()));
    // }
  }

  void _injectPrintInterceptor(InAppWebViewController controller) async {
    // 注入JavaScript代码来拦截window.print()调用
    const String printInterceptorScript = '''
      (function() {
        // 保存原始的window.print函数
        const originalPrint = window.print;
        
        // 重写window.print函数
        window.print = function(htmlContent) {
          // 如果没有传入HTML内容，则使用当前页面内容
          const contentToPrint = htmlContent || document.documentElement.outerHTML;
          
          // 发送消息到Flutter
          window.flutter_inappwebview.callHandler('onPrintRequested', {
            url: window.location.href,
            title: document.title,
            content: contentToPrint,
            timestamp: new Date().toISOString(),
            isCustomContent: !!htmlContent
          });
          
          // 可以选择是否调用原始打印函数
          // return originalPrint.apply(this, arguments);
        };
        
        // 添加一个自定义的打印函数供H5调用
        window.flutterPrint = function(htmlContent, options = {}) {
          const contentToPrint = htmlContent || document.documentElement.outerHTML;
          
          window.flutter_inappwebview.callHandler('onPrintRequested', {
            url: window.location.href,
            title: document.title,
            content: contentToPrint,
            timestamp: new Date().toISOString(),
            isCustomContent: !!htmlContent,
            ...options
          });
        };
        
        console.log('Print interceptor injected successfully');
      })();
    ''';

    await controller.evaluateJavascript(source: printInterceptorScript);
  }

  void _handleConsoleMessage(ConsoleMessage consoleMessage) {
    // 处理控制台消息，可以用于调试
    print('WebView Console: ${consoleMessage.message}');
  }

  @override
  void initState() {
    super.initState();
    _setupPrintHandler();
  }

  void _setupPrintHandler() {
    // JavaScript处理器将在WebView创建时设置
  }

  void _setLocalStorage(InAppWebViewController controller, String data) async {
    final String script = "localStorage.setItem('loginInfo', '$data');";
    await controller.evaluateJavascript(source: script);
    print('Login info set in localStorage: $data');
  }

  // 网页js调用
  void _setupJavaScriptHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onPrintRequested',
      callback: (args) {
        _handlePrintRequest(args);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'showGlobalDialog',
      callback: (args) {
        if (args.isNotEmpty && args[0] is String && args[1] is String) {
          GlobalDialog.show(context, args[0], args[1]);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'openFullscreenPopup',
      callback: (args) {
        _handleOpenFullscreenPopup(args);
      },
    );
  }

  // 弹窗网页js调用
  void _setupModalJavaScriptHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'closeFullscreenPopup',
      callback: (args) {
        if (_dialogContext != null && Navigator.of(_dialogContext!).canPop()) {
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null; // 弹窗关闭时置为null
          // 触发另一个网页的事件
          controller.evaluateJavascript(
            source: 'window.postMessage({type: "closeFullscreenPopup"}, "*");'
          );
        }
      },
    );
  }

  // 弹窗打开时，弹窗内容
  // TODO优化建议：如果弹窗频繁打开且内容相同，可以考虑将 `InAppWebView` 实例提升到父组件的状态中，并在弹窗关闭时不销毁，而是隐藏，下次打开时直接显示已存在的实例
  void _handleOpenFullscreenPopup(List<dynamic> args) {
    final String url = args[0] as String;
    if (url.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          _dialogContext =
              dialogContext; // Assign dialogContext to _dialogContext
          return Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(url)),
                  onWebViewCreated: (controller) {
                    _setupModalJavaScriptHandler(controller);
                  },
                  onLoadStop: (controller, url) async {
                    print('加载完成: ${url?.toString()}');
                    _injectPrintInterceptor(controller);
                    if (widget.localStorageData != null) {
                      _setLocalStorage(controller, widget.localStorageData!);
                    }
                  },
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      if (_dialogContext != null &&
                          Navigator.of(_dialogContext!).canPop()) {
                        Navigator.of(_dialogContext!).pop();
                        _dialogContext = null; // 弹窗关闭时置为null
                        // 确保弹窗中的WebView也被销毁
                        // 这里可能需要更复杂的逻辑来获取并销毁弹窗中的InAppWebViewController
                        // 但目前没有直接获取弹窗内WebView控制器的方法，只能依赖Flutter的Widget树销毁机制
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _handlePrintRequest(List<dynamic> args) async {
    if (args.isNotEmpty && args[0] is Map) {
      final printData = Map<String, dynamic>.from(args[0]);

      print('收到打印请求:');
      print('URL: ${printData['url']}');
      print('标题: ${printData['title']}');
      print('时间戳: ${printData['timestamp']}');

      // 直接执行静默打印
      _printAsPDF(printData);
    }
  }

  void _printAsPDF(Map<String, dynamic> printData) async {
    try {
      // 创建PDF文档
      // final pdf = pw.Document();

      // 获取HTML内容
      // final String htmlContent = printData['content'] ?? '';
      // final bool isCustomContent = printData['isCustomContent'] ?? false;
      // 常用示例注释
      // `<h1>Heading Example</h1>
      //     <p style="color:red">This is a paragraph.</p>
      //     <blockquote>This is a quote.</blockquote>
      //     <img style="width:100px;height:100px" src"https://pic.rmb.bdstatic.com/bjh/bb839a9094c/241114/83649790e78b8e2628ff726e6f176ea7.jpeg?for=bg" />
      //     <ul>
      //       <li>First item</li>
      //       <li>Second item</li>
      //       <li>Third item</li>
      //     </ul>`
      // await Printing.layoutPdf(
      //   onLayout: (PdfPageFormat format) async {
      //     final pdf = pw.Document();
      //     final widgets = await pdfToHtml.HTMLToPdf().convert(htmlContent, wrapInParagraph: true);
      //     pdf.addPage(pw.MultiPage(build: (context) => widgets));
      //     return await pdf.save();
      //   },
      // );
      // 打印本地html
      print("255");
      final pdf2 = await rootBundle.load('Document2222.pdf');
      await Printing.layoutPdf(onLayout: (_) => pdf2.buffer.asUint8List());
      print("266");
    } catch (e) {
      print(e);
      print("299");
    }
  }
}
