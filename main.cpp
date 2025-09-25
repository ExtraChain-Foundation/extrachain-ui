#include "metatypes.h"

#ifndef RACCOON_CONSOLE
#include "SRC/ClientController.h"
#include "SRC/RaccoonController.h"
#include <QIcon>
#include <QQmlApplicationEngine>
#include <qguiapplication.h>
#ifdef USE_QZXING
#include "QZXing.h"
#endif

#if !defined(Q_OS_IOS)
#include "SRC/Helper.h"
#include "SRC/HelperMacOs.h"
#endif
#else
#if !defined(Q_OS_IOS)
#include "SRC/Helper.h"
#endif
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include "SRC/consolecommandprocessor.h"
#endif

#include "managers/logs_manager.h"

#if defined(Q_OS_IOS)
#include "ios/FilePicker.h"
#include "ios/ImagePicker.h"
#endif

#if defined(RACCOON_CONSOLE) && !defined(RACCOON_CLIENT_CONSOLE)
const std::string predefine_token_id =
    "[\"468faf2f1be6504a9a26f7f027f7e43380b0d77d\",2,"
    "\"YSa4cmnQ8NsaZTOe3n3LzBo9LXHVB4PIz2iHcsyH3cI\","
    "\"8ueBTAdbr4zJckpYu3R__tCTPG9n_"
    "hziXySAdkMy5dFhJrhyadDw2xplM57efcvMGj0tcdUHg8jPaIdyzIfdwg\"]";

const std::string predefine_raccoon_id =
    "[\"46710a2d823c23db9fc2ac01e0f84212a8128373\",1,"
    "\"lwiqDsEnbrfmYWDqshZDVCGpHs6ahbEHYykzCkrSutE\","
    "\"MU3JIBdQ7MA1ncYfLsXTL95a0Mxq3Fs_oNO_Ot1IPQyXCKoOwSdut-"
    "ZhYOqyFkNUIakezpqFsQdjKTMKStK60Q\"]";
#endif

int main(int argc, char *argv[]) {
  Utils::prepare_extrachain();

#ifdef Q_OS_IOS
  QGuiApplication app(argc, argv);
  QGuiApplication::setAttribute(Qt::AA_DisableHighDpiScaling);
  registerMetaTypes();

  app.setWindowIcon(QIcon(":/UI/Images/extrachain_lite.png"));
  qmlRegisterSingletonType(QUrl("qrc:/UI/Colors.qml"), "ExtraChain", 1, 0,
                           "Colors");
  qmlRegisterSingletonType(QUrl("qrc:/UI/UiSettings.qml"), "ExtraChain", 1, 0,
                           "UiSettings");
  qmlRegisterSingletonType(QUrl("qrc:/UI/Fonts.qml"), "ExtraChain", 1, 0,
                           "Montserrat");
  qmlRegisterSingletonType(QUrl("qrc:/UI/IcoMoonSettings.qml"), "ExtraChain", 1,
                           0, "IcoMoon");
  qmlRegisterSingletonType(QUrl("qrc:/UI/Utils.qml"), "ExtraChain", 1, 0,
                           "Utils");

  qmlRegisterType<MenuSelector>("ExtraChain", 1, 0, "MenuSelector");
  qmlRegisterType<Onboarding>("ExtraChain", 1, 0, "Onboarding");
  qmlRegisterType<Tooltip>("ExtraChain", 1, 0, "Tooltip");
  qmlRegisterType<ConnectStatus>("ExtraChain", 1, 0, "ConnectStatus");
  qmlRegisterType<ImagePicker>("ExtraChain", 1, 0, "ImagePicker");

  QQmlApplicationEngine engine;
#ifdef USE_QZXING
  QZXing::registerQMLTypes();
  QZXing::registerQMLImageProvider(engine);
#endif

  RaccoonFilePicker filePicker;
  engine.rootContext()->setContextProperty("filePicker", &filePicker);

  std::unique_ptr<RaccoonController> roc =
      std::make_unique<RaccoonController>(&engine);
  engine.rootContext()->setContextProperty("raccoonController", roc.get());

  const QUrl mainQmlUrl("qrc:/Main.qml");
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

  engine.load(mainQmlUrl);

  return app.exec();
#else
#ifdef RACCOON_CLIENT_CONSOLE
  LogsManager::debugLogs = false;
#else
  LogsManager::debugLogs = true;
#endif

#if defined(Q_OS_LINUX) && !defined(QT_DEBUG) &&                               \
    (defined(IS_RC) || defined(RACCOON_CLIENT_CONSOLE))
  Logger::instance().set_compact_console(false);
  LogsManager::debugLogs = false;
#endif

  LogsManager::etHandler();
  Logger::instance().set_debug(LogsManager::debugLogs);

  std::thread consoleInputThread;
  if (QString(CMAKE_GENERATOR) != xcode_generator) {
    std::string firstArgWin = argc > 1 ? argv[1] : "";
    std::string prefixWin = "-qmljsdebugger";

    bool isAlwaysConsole = false;
#ifdef RACCOON_CLIENT_CONSOLE
    isAlwaysConsole = true;
#endif

    if (isAlwaysConsole ||
        (argc > 1 &&
         firstArgWin.compare(0, prefixWin.length(), prefixWin) != 0)) {
#ifndef QT_DEBUG
      try {
#endif
        std::thread consoleInputThread;
        runConsoleRaccoon(argc, argv, consoleInputThread);
        if (consoleInputThread.joinable()) {
          consoleInputThread.join();
        }
#ifndef QT_DEBUG
      } catch (const std::exception &err) {
        eLog("Unable to start service as {}, error: {}", std::string(argv[2]),
             err.what());
        return 1;
      } catch (...) {
        eLog("Unable to start service as {}, unknown error!",
             std::string(argv[2]));
        return 1;
      }
#endif
    } else {
#ifndef QT_DEBUG
      try {
#endif
        runRaccoon(argc, argv);
#ifndef QT_DEBUG
      } catch (const std::exception &err) {
        std::cout << "EXCEPTION: " << err.what() << std::endl;
        return 1;
      } catch (...) {
        std::cout << "EXCEPTION UNKNOWN" << std::endl;
        return 1;
      }
#endif
    }
  } else {
    runRaccoon(argc, argv);
  }

  if (consoleInputThread.joinable()) {
    consoleInputThread.join();
  }
#endif
}
