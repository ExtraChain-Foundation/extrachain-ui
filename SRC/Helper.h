#include "SRC/HelperMacOs.h"
#include "managers/token_manager.h"
#include <QLockFile>
#include <csignal>
#include <iostream>

#ifdef Q_OS_IOS
#include <QStandardPaths>
#endif

#include <QCommandLineParser>
#include <QDir>

#include "chain/actor_index.h"
#include "dfs/dfs_controller.h"
#include "network/network_manager.h"
#include "utils/bignumber.h"

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include <QProcess>

#include "SRC/helper_linux.h"
#endif

#ifdef Q_OS_UNIX
#include <unistd.h>
#endif

#include "SRC/Model/MessengerController.h"
#include "SRC/platforms/android/androidutils.h"

#ifndef Q_OS_IOS
#include "SRC/consolecommandprocessor.h"
#endif

#ifndef EXTRACHAIN_CONSOLE
#include "QtGui/qicon.h"
#include "SRC/ExtraChainController.h"
#include "SRC/statusbarhelper.h"
#include "blurhash.h"
#include <QQuickWindow>
#include <QSettings>
#ifdef USE_QZXING
#include "QZXing.h"
#endif
#else
#include "SRC/updater.h"
#endif

#if defined(EXTRACHAIN_CONSOLE) && !defined(EXTRACHAIN_CLIENT_CONSOLE)
extern const std::string predefine_token_id;
extern const std::string predefine_extrachain_id;
#endif

#include "metatypes.h"

#include "extrachain_version.h"

#ifdef Q_OS_WIN
#include <conio.h>

const char *strsignal(int sig) {
  static const std::unordered_map<int, const char *> sig2NameMap = {
      {SIGINT, "SIGINT"},
      {SIGTERM, "SIGTERM"},
      {SIGABRT, "SIGABRT"},
      {SIGSEGV, "SIGSEGV"}};

  const auto iter = sig2NameMap.find(sig);
  if (iter != sig2NameMap.end())
    return iter->second;

  return "Unknown";
}
#endif

static const char *xcode_generator = "Xcode";
constexpr int delta_time_ten_sec = 10000;

namespace Token {
static const auto one_billion = BigNumberFloat("1000000000", NumeralBase::Dec);
static const std::string rocc_token = "ROCC";
static const std::string rocc_symbol = "ROCC";
ActorId rocc_token_id = ActorId();
} // namespace Token

static void HandleSignal(int sig) {
  try {
    switch (sig) {
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    case SIGQUIT:
#endif
    case SIGINT:
    case SIGTERM: {
      eCritical("Signal achieved:  {}", strsignal(sig));
      QCoreApplication::quit();
      break;
    }
    case SIGABRT:
    case SIGSEGV: {
      eCritical("Catch signal:  {}", strsignal(sig));

      // TODO: stacktrace
      eCritical("Here should be stacktrace!");
      // #ifdef Q_OS_LINUX
      //             std::ostringstream oss;
      //             oss << boost::stacktrace::stacktrace();
      //             QStringList lines =
      //             QString::fromStdString(oss.str()).split('\n');

      //             eCritical("Stack trace:");
      //             for (const QString& line : lines)
      //                 eCritical("{}", line.toStdString());
      // #endif

      if (sig == SIGSEGV)
        _exit(EXIT_FAILURE);
      else
        exit(EXIT_FAILURE);

      std::exit(EXIT_FAILURE);
    }
    default:
      exit(EXIT_FAILURE);
    }
  } catch (const std::exception &ex) {
    eCritical("SignalHandler exception:  {}", ex.what());
    _exit(EXIT_FAILURE);
  }
}

bool SetupSignals() {
#ifdef Q_OS_WIN
  constexpr const std::array<int, 4> arrSig = {
      {SIGINT, SIGTERM, SIGSEGV, SIGABRT}};
#else
  constexpr const std::array<int, 5> arrSig = {
      {SIGINT, SIGTERM, SIGSEGV, SIGABRT, SIGQUIT}};
#endif

  for (const auto &item : arrSig) {
    if (signal(item, HandleSignal) == SIG_ERR) {
      eCritical(
          "{}",
          "Cannot handle a signal: " + QString::fromStdString(strsignal(item)) +
              ", reason - " + QString::fromStdString(strerror(errno)));
      return false;
    }
  }

  return true;
}

#ifdef Q_OS_WIN
#include <Windows.h>
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib")

void setCustomTitleBarColor(HWND hwnd) {
  COLORREF titleBarColor = RGB(0x0D, 0x0A, 0x20); // RGB(13, 10, 32) #0D0A20
  DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &titleBarColor,
                        sizeof(titleBarColor));
  DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &titleBarColor,
                        sizeof(titleBarColor));
  COLORREF textColor = RGB(255, 255, 255);
  DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, &textColor, sizeof(textColor));
}

void setTitleBarColor(QWindow *window) {
  if (window && window->winId()) {
    HWND hwnd = (HWND)window->winId();
    setCustomTitleBarColor(hwnd);
  }
}
#endif

inline int runExtrachain(int argc, char *argv[]) {
#ifndef EXTRACHAIN_CONSOLE
  QGuiApplication app(argc, argv);

  app.setApplicationName("ExtraChain");
  app.setOrganizationName("EXTRACHAIN TECHNOLOGY LTD");
  app.setOrganizationDomain("https://extrachain.com/");

  AndroidUtils::setOrientationBasedOnDeviceType();
  // AndroidUtils::setWakeLock(true);
  AndroidUtils::initialize();

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  if (!RaccoonLinux::isRunningAsRoot()) {
    eInfo("Root access required");
    // eInfo("Usage: sudo {}",
    // QFileInfo(QCoreApplication::applicationFilePath()).fileName());
    return 1;
  }
#endif

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
  qmlRegisterType<MessegeDelegateType>("ExtraChain", 1, 0,
                                       "MessegeDelegateType");

  bool isSoftwareRendering = false;
  {
    QSettings settings;
    isSoftwareRendering = settings.value("softwareRendering", false).toBool();
  }

  if (isSoftwareRendering) {
#ifdef Q_OS_ANDROID
    QSurfaceFormat fmt;
    fmt.setRenderableType(QSurfaceFormat::OpenGLES);
    fmt.setVersion(3, 0);
    fmt.setProfile(QSurfaceFormat::NoProfile);
    fmt.setDepthBufferSize(0);
    fmt.setStencilBufferSize(0);
    QSurfaceFormat::setDefaultFormat(fmt);
#else
    QQuickWindow::setSceneGraphBackend("software");
#endif
  }

  QQmlApplicationEngine engine;
#ifdef USE_QZXING
  QZXing::registerQMLTypes();
  QZXing::registerQMLImageProvider(engine);
#endif
  engine.addImageProvider("blurhash", new BlurHashImageProvider());

  auto extraChainController = std::make_unique<ExtraChainController>(&engine);

  engine.rootContext()->setContextProperty("extraChainController",
                                           extraChainController.get());
  engine.rootContext()->setContextProperty("isSoftwareRendering",
                                           isSoftwareRendering);
  engine.rootContext()->setContextProperty("isTablet",
                                           AndroidUtils::isTablet());

  auto statusBarHelper = StatusBarHelper();
  engine.rootContext()->setContextProperty("statusBarHelper", &statusBarHelper);

#ifdef EXTRACHAIN_MESSENGER
  engine.rootContext()->setContextProperty("isMessenger", true);
#else
  engine.rootContext()->setContextProperty("isMessenger", false);
#endif

  bool appOpened = false;

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
  static QLockFile lockFile(".ExtraChain.lock");
  if (!lockFile.tryLock(100)) {
    appOpened = true;
  }
#endif

  QString mainQmlFile =
      !appOpened ? "qrc:/Main.qml" : "qrc:/UI/MessageWindow.qml";

  if (!appOpened) {
    static FilePicker filePicker;
    engine.rootContext()->setContextProperty("filePicker", &filePicker);
  }

  const QUrl mainQmlUrl(mainQmlFile);
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.load(mainQmlUrl);

#ifdef Q_OS_WIN
  QObject *rootObject = engine.rootObjects().first();
  QQuickWindow *window = qobject_cast<QQuickWindow *>(rootObject);

  if (window) {
    setTitleBarColor(window);
  }
#endif

  return app.exec();
#else
  return -666;
#endif
}

void runConsoleExtrachainInput(ExtraChainNode *node) {
  std::string command;
  bool running = true;
  ConsoleCommandProcessor inputProcessor(*node);
  while (running) {
    std::getline(std::cin, command);
    if (!command.empty()) {
      std::cout << "Received command: " << command << std::endl;
      inputProcessor.processInputCommand(command);
      if (command == "exit") {
        running = false;
      }
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(3000));
  }
  QMetaObject::invokeMethod(QCoreApplication::instance(), "quit",
                            Qt::QueuedConnection);
}

QString readPassword(const QString &prompt) {
  QTextStream out(stdout);
  out << prompt;
  out.flush();

#ifdef Q_OS_WIN
  // Windows implementation
  QString password;
  char ch;
  while ((ch = _getch()) != '\r') { // Enter key
    if (ch == '\b') {               // Backspace
      if (!password.isEmpty()) {
        password.chop(1);
        out << "\b \b";
      }
    } else {
      password += ch;
      out << '*';
    }
    out.flush();
  }
  out << "\n";
  return password;
#else
  // Unix/Linux/macOS
  QProcess::execute("stty", QStringList() << "-echo");
  QTextStream in(stdin);
  QString password = in.readLine();
  QProcess::execute("stty", QStringList() << "echo");
  out << "\n";
  return password.trimmed();
#endif
}

inline int runConsoleExtrachain(int argc, char *argv[],
                                std::thread &consoleInputThread) {
#ifdef EXTRACHAIN_CLIENT_CONSOLE
  Logger::instance().set_compact_console(true);
  // Logger::instance().set_debug(true);
#endif

#if defined(__aarch64__) || defined(__arm64__)
  const char *arch = "arm64";
#elif defined(__x86_64__)
  const char *arch = "x86_64";
#else
  const char *arch = "Unknown";
#endif

  eInfo("ExtraChain Core version: {}\n", extrachain_version);

  QCoreApplication app(argc, argv);
  app.setApplicationName("ExtraChain Console");
  app.setOrganizationName("EXTRACHAIN TECHNOLOGY LTD");
  app.setOrganizationDomain("https://extrachain.com/");

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
  // RaccoonLinux::processInterface();

  if (!RaccoonLinux::isRunningAsRoot()) {
    eInfo("Root access required");
    // eInfo("Usage: sudo {}",
    // QFileInfo(QCoreApplication::applicationFilePath()).fileName());
    return 1;
  }
#endif

  if (!SetupSignals())
    exit(EXIT_FAILURE);

  registerMetaTypes();

  QCommandLineParser parser;
  parser.setApplicationDescription("Extrachain Console Client");
  parser.addHelpOption();
  parser.addVersionOption();

  QCommandLineOption loginOption("login", "Set login", "login");
  QCommandLineOption passOption("password", "Set password", "password");
  QCommandLineOption registration("registration",
                                  "Create new profile with login and password");
  QCommandLineOption importOption("import-profile",
                                  "Choose profile file for import", "file");
  QCommandLineOption importPhraseOption(
      "import-phrase", "Import seed phrase or hex for wallet recovery");
  QCommandLineOption showPhraseOption(
      "show-phrase", "Import seed phrase or hex for wallet recovery");
  QCommandLineOption showHexOption(
      "show-hex", "Import seed phrase or hex for wallet recovery");
  QCommandLineOption dagMode(
      "dag-mode", "Choose dag mode: full (higher rewards) / light", "mode");
  QCommandLineOption dfsMode(
      "dfs-mode", "Choose dfs mode: full (higher rewards) / light", "mode");

  QCommandLineOption connectToNode("connect-to-node",
                                   "Connect to existing node by IP", "ip");

  parser.addOptions({loginOption, passOption, registration, showPhraseOption,
                     showHexOption, importOption, importPhraseOption, dagMode,
                     dfsMode});

#ifdef EXTRACHAIN_CLIENT_CONSOLE
#ifdef QT_DEBUG
  parser.addOption(connectToNode);
#endif
#else
  // QCommandLineOption console({ "console", "c" }, "Console application");
  QCommandLineOption clearDataOption("clear-data", "Wipe all data");
  QCommandLineOption subscriptionOption(
      "create-subscription-vector",
      "Create subscription vector from local system id");

  parser.addOptions({clearDataOption, connectToNode, subscriptionOption});
#endif

  parser.process(app);

#ifdef EXTRACHAIN_CLIENT_CONSOLE
  QTimer updateTimer;

  QObject::connect(&updateTimer, &QTimer::timeout, []() {
    Updater updater(nullptr);
    auto [can_update, version] = updater.checkForUpdates();
    if (can_update) {
      eInfo("New version available: {}", version);
      updater.update();

      QString updaterPath = QDir::currentPath() + "/ExtraChain_Update.tar.gz";
      QFile updaterFile(updaterPath);
      if (updaterFile.exists() && updaterFile.size() != 0) {
        updater.install();
        std::exit(0);
      }
    }
  });

  {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(50, 70);
    int intervalMinutes = dis(gen);
    updateTimer.start(intervalMinutes * 60 * 1000);
  }

  Updater updater(nullptr);
  auto [can_update, version] = updater.checkForUpdates();
  if (can_update) {
    eInfo("New version available: {}", version);
    updater.update();

    QString updaterPath = QDir::currentPath() + "/ExtraChain_Update.tar.gz";
    QFile updaterFile(updaterPath);
    if (updaterFile.exists() && updaterFile.size() != 0) {
      updater.install();
    }
    return 0;
  } else {
    // eInfo("You have actual version");
  }
#endif

  {
    QString currentPath = qApp->applicationDirPath();
#ifdef Q_OS_IOS
    currentPath =
        QStandardPaths::standardLocations(QStandardPaths::DocumentsLocation)
            .value(0);
#endif

#ifdef QT_DEBUG
    QString folder = Utils::dataDir("test-data");
#else
    QString folder = Utils::dataDir("public-data");
#endif

    currentPath += "/" + folder;
    if (QDir(currentPath).exists())
      QDir::setCurrent(currentPath);
    else {
      QDir().mkpath(currentPath);
      QDir::setCurrent(currentPath);
    }

    eInfo("Working folder: {}", currentPath);
  }

  Logger::start_file("extrachain");
  eLog("ExtraChain version {}", extrachain_version);

  // static QLockFile lockFile(".ExtraChain.lock");
  // if (!lockFile.tryLock(100)) {
  //     fmt::println("ExtraChain Console already running in directory {}",
  //     QDir::currentPath()); std::exit(0);
  // }

  bool isMainExtrachain = false;
#ifndef EXTRACHAIN_CLIENT_CONSOLE
  if (parser.isSet(clearDataOption) || QFile("wipe").exists()) {
    eLog("Make wipe...");
    Utils::wipeDataFiles();
  }
#endif

  if (!parser.isSet(loginOption) || parser.value(loginOption).isEmpty())
      [[unlikely]] {
    eInfo("Login is not set or empty. Please, use --login <login>");
    return 1;
  }

  if (!parser.isSet(passOption) || parser.value(passOption).isEmpty())
      [[unlikely]] {
    eInfo("Password is not set or empty. Please, use --password <password>");
    return 1;
  }

  QString login = parser.value(loginOption);
  QString password = parser.value(passOption);

  auto filesToDelete = std::make_shared<QStringList>();
  ExtraChainNodeWrapper *nodeWrapper =
      new ExtraChainNodeWrapper(&app, false, true);
  nodeWrapper->init();

  auto dagModeStr = parser.value(dagMode);
  if (dagModeStr.toLower() == "light") {
    nodeWrapper->node->dag()->set_mode(DagMode::Light);
  } else {
    nodeWrapper->node->dag()->set_mode(DagMode::Full);
  }

  auto dfsModeStr = parser.value(dfsMode);
  if (dfsModeStr.toLower() == "light") {
    nodeWrapper->node->dfs()->set_mode(DfsMode::Light);
  } else {
    nodeWrapper->node->dfs()->set_mode(DfsMode::Full);
  }

  auto bytesAvailable = Utils::diskAvailableMemory();
  double gbAvailable =
      static_cast<double>(bytesAvailable) / (1024.0 * 1024.0 * 1024.0);

  if (gbAvailable < 16.5) {
    eInfo("Warning: available only {} GB, set Dag and Dfs to light mode",
          gbAvailable);
    nodeWrapper->node->dag()->set_mode(DagMode::Light);
    nodeWrapper->node->dfs()->set_mode(DfsMode::Light);
  } else if (gbAvailable < 40.0) {
    eInfo("Warning: available only {} GB, set Dfs to light mode", gbAvailable);
    nodeWrapper->node->dfs()->set_mode(DfsMode::Light);
  }

  eInfo("Dag Mode: {}. Dfs Mode: {}",
        nodeWrapper->node->dag()->mode() == DagMode::Light ? "Light" : "Full",
        nodeWrapper->node->dfs()->mode() == DfsMode::Light ? "Light" : "Full");

  SectionId sync_to = SectionId(-1);

  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagStatus,
                   [](DagStatus status) {
                     switch (status) {
                     case DagStatus::Ready:
                       eInfo("AcyclicChain ready - mining is active");
                       break;
                     case DagStatus::Sync:
                       eInfo("AcyclicChain synchronization started...");
                       break;
                     default:
                       break;
                     }
                   });
  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagSyncStart,
                   [&sync_to](SectionId from_section, SectionId to_section) {
                     sync_to = to_section;
                     // eInfo("AcyclicChain synchronization started: from
                     // section 0x{} to section 0x{}",
                     //       from_section,
                     //       to_section);
                   });
  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagSyncProgress,
                   [&sync_to](SectionId section_id) {
                     auto percent = ((section_id * 100) / sync_to).to_int();

#ifdef Q_OS_UNIX
                     if (isatty(STDOUT_FILENO)) {
                       fmt::print("\rProgress: {} / {} sections ({}%)",
                                  section_id.to_string(NumeralBase::Dec),
                                  sync_to.to_string(NumeralBase::Dec),
                                  percent.has_value() ? percent.value() : 0);
                       std::cout.flush();
                     } else {
#endif
                       fmt::println("Progress: {} / {} sections ({}%)",
                                    section_id.to_string(NumeralBase::Dec),
                                    sync_to.to_string(NumeralBase::Dec),
                                    percent.has_value() ? percent.value() : 0);
                       std::cout.flush();
#ifdef Q_OS_UNIX
                     }
#endif
                   });
  // QObject::connect(nodeWrapper->node, &ExtraChainNode::dagTxSended,
  // [](SectionId id, const std::string& hash)
  // {
  //     eInfo("AcyclicChain transaction sent: section 0x{}, hash {}", id,
  //     hash);
  // });
  // QObject::connect(nodeWrapper->node, &ExtraChainNode::dagTxApproved,
  // [](SectionId id, const std::string& hash) {
  //     eInfo("AcyclicChain transaction approved: section 0x{}, hash {}", id,
  //     hash);
  // });
  // QObject::connect(nodeWrapper->node,
  //                  &ExtraChainNode::dagTxNotApproved,
  //                  [](SectionId id, const std::string& hash) {
  //                      eInfo("AcyclicChain transaction rejected: section {},
  //                      hash {}", id, hash);
  //                  });
  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagControlStarted,
                   []() { eInfo("Generating controls for AcyclicChain..."); });
  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagControlEnded, []() {
    eInfo("AcyclicChain controls generation completed");
  });
  QObject::connect(
      nodeWrapper->node, &ExtraChainNode::dagSearchControlStarted,
      []() { eInfo("Checking the integrity of AcyclicChain..."); });
  QObject::connect(nodeWrapper->node, &ExtraChainNode::dagSearchControlEnded,
                   []() { eInfo("AcyclicChain integrity check completed"); });

  QObject::connect(nodeWrapper->node->dfs(), &DfsController::added,
                   [](ActorId owner_id, Dfs::DirRow dirRow) {
                     eLog("[Console/DFS] Added {}", dirRow);
                   });
  QObject::connect(nodeWrapper->node->dfs(), &DfsController::uploaded,
                   [](ActorId owner_id, Dfs::DirRow dirRow) {
                     eLog("[Console/DFS] Uploaded {}", dirRow);
                   });
  QObject::connect(nodeWrapper->node->dfs(), &DfsController::downloaded,
                   [](ActorId owner_id, Dfs::DirRow dirRow) {
                     eLog("[Console/DFS] Downloaded {}", dirRow);
                   });
  QObject::connect(nodeWrapper->node->dfs(), &DfsController::downloadProgress,
                   [](ActorId actorId, std::string fileId, int progress) {
                     eLog("[Console/DFS] Download progress: {} {} {}", actorId,
                          fileId, progress);
                   });
  QObject::connect(nodeWrapper->node->dfs(), &DfsController::uploadProgress,
                   [](ActorId actorId, std::string fileId, int progress) {
                     eLog("[Console/DFS] Upload progress: {} {} {}", actorId,
                          fileId, progress);
                   });

  /*
  QObject::connect(nodeWrapper->node->blockchain(), &Blockchain::updateSelf,
  [nodeWrapper](BigNumber actorId) { const auto& result =
  nodeWrapper->node->blockchain()->read_block_by_id(actorId); if
  (!result.has_value()) { return; } else { const BlockVariant& block =
  result.value(); for (const Transaction& tx : block.transactions()) { if
  (tx.token() != ActorId("468faf2f1be6504a9a26f7f027f7e43380b0d77d")) continue;

              for (const ActorId& accountId :
  nodeWrapper->node->account_controller()->accountsIds()) { if (tx.receiver() ==
  accountId) eInfo("Received {} ROCC",
  tx.amount().to_string(NumeralBase::Dec).substr(0, 6));
              }
          }
      }
  });
  */

  bool loginResult = nodeWrapper->node->account_controller()->count() > 0;
  std::string loginHash;
  // AutologinHash autologinHash;
  // if (1AutologinHash::isAvailable() && autologinHash.load())
  //     loginHash = autologinHash.hash();
  // else {
  loginHash = Utils::calculate_hash((login + password).toStdString());
  // }

  if (isMainExtrachain) {
#if defined(EXTRACHAIN_CONSOLE) && !defined(EXTRACHAIN_CLIENT_CONSOLE)
    Actor<KeyPrivate> EXTRACHAIN_actor;
    EXTRACHAIN_actor = EXTRACHAIN_actor.fromJson(
        QByteArray::fromStdString(predefine_EXTRACHAIN_id));

    nodeWrapper->node->account_controller()->create_profile(
        loginHash, ActorType::User, EXTRACHAIN_actor);
    eInfo("Created profile with your login and password");
    loginResult = true;
#endif
  } else {
    if (parser.isSet(importOption)) {
      auto result = nodeWrapper->node->import_profile_file(
          parser.value(importOption).toStdString(), login.toStdString(),
          password.toStdString());
      if (result.has_value()) {
        // eInfo("Profile imported successfully");
      } else {
        std::exit(0);
      }
    }

    if (parser.isSet(importPhraseOption)) {
      QTextStream in(stdin);

      fmt::println("");
      eInfo("What would you like to import?");
      eInfo("1. Seed phrase (mnemonic words)");
      eInfo("2. Hex seed");
      eInfo("Enter choice (1 or 2): ");

      QString choice = in.readLine().trimmed();

      QString importData;
      bool success = false;

      if (choice == "1") {
        eInfo("Enter seed phrase: ");
        importData = in.readLine().simplified().trimmed();

        if (importData.isEmpty()) {
          eInfo("Seed phrase cannot be empty");
          return 1;
        }

        bool validate =
            nodeWrapper->node->account_controller()->validate_mnemonic(
                importData.toStdString());
        if (!validate) {
          eInfo("Incorrect phrase");
        }

        eInfo("Importing seed phrase...");
        success = nodeWrapper->node->account_controller()->import_seed_phrase(
            login.toStdString(), password.toStdString(),
            importData.toStdString());

      } else if (choice == "2") {
        eInfo("Enter hex seed: ");
        importData = in.readLine().simplified().trimmed();

        if (importData.isEmpty()) {
          eInfo("Hex seed cannot be empty");
          return 1;
        }

        eInfo("Importing hex seed...");
        success = nodeWrapper->node->account_controller()->import_seed_hex(
            login.toStdString(), password.toStdString(),
            importData.toStdString());

      } else {
        eInfo("Invalid choice: {}. Please enter 1 or 2.", choice.toStdString());
        return 1;
      }

      if (success) {
        eInfo("Import completed successfully");
      } else {
        eInfo("Import failed");
        return 1;
      }
    }

    password.clear();

    if (nodeWrapper->node->account_controller()->count() == 0) {
      loginResult = nodeWrapper->node->login(loginHash).has_value();
      if (!loginResult) {
        if (!parser.isSet(registration) &&
            AccountController::profiles_list().size() != 0) {
          eInfo("Error: Incorrect login or password");
          std::exit(-1);
        } else {
          if (!parser.isSet(registration)) {
            eInfo("Warning: No profile files found. Use --registration to "
                  "create new profile");
          }

#ifdef EXTRACHAIN_CLIENT_CONSOLE
          if (!parser.isSet(registration)) {
            std::exit(0);
          }
#endif
          nodeWrapper->node->account_controller()->create_profile(
              loginHash, ActorType::User);

          fmt::println(
              "Mnemonic phrase: {}",
              fmt::join(
                  nodeWrapper->node->account_controller()->seed_mnemonic(),
                  " "));
          fmt::println("Hex (encrypted with login and password): {}",
                       nodeWrapper->node->account_controller()->seed_hex());

          loginResult = true;
        }
      } else {
#ifdef EXTRACHAIN_CLIENT_CONSOLE
        if (parser.isSet(registration)) {
          eInfo("Registration not required, just login");
        }
#endif

        eInfo("Login successfully");
      }
    }
  }
  if (loginResult) {
    auto network = nodeWrapper->node->network();

    if (parser.isSet(connectToNode)) {
      network->save_first_node(parser.value(connectToNode).toStdString());
    }

    if (parser.isSet(showPhraseOption) || parser.isSet(showHexOption)) {
      fmt::println(
          "Mnemonic phrase: {}",
          fmt::join(nodeWrapper->node->account_controller()->seed_mnemonic(),
                    " "));
      fmt::println("Hex (encrypted with login and password): {}",
                   nodeWrapper->node->account_controller()->seed_hex());
    }

    network->connect_network();
  }

#if defined(EXTRACHAIN_CONSOLE) && !defined(EXTRACHAIN_CLIENT_CONSOLE)
  if (isMainExtraChain) {
    QObject::connect(
        nodeWrapper->node->network(),
        &NetworkManager::newSocketActivatedWithParams,
        [&nodeWrapper](const std::string _1, const std::string _2) {
          static bool create = false;

          if (create) {
            return;
          }

          create = true;

          QTimer::singleShot(1000, [&nodeWrapper] {
            auto owner = nodeWrapper->node->account_controller()
                             ->current_profile()
                             .system()
                             .id();
            auto tokenManager = nodeWrapper->node->token_manager();

            auto tokenDataExpected = tokenManager->create_token(
                owner, Token::rocc_token, Token::rocc_symbol,
                Token::one_billion, "#071b30", predefine_token_id);

            if (tokenDataExpected.has_value()) {
              eSuccess("ExtraChain token created and sended to network: {}",
                       tokenDataExpected.value().owner_id);
              Token::rocc_token_id = tokenDataExpected.value().token_id;
              eLog("Token rocc id is  {}", Token::rocc_token_id);
            } else {
              eFatal("[Create Token] Error: {}", tokenDataExpected.error());
            }
          });
        });
  }
#endif

#ifndef EXTRACHAIN_CLIENT_CONSOLE
  bool subscription_create = parser.isSet(subscriptionOption);

  if (subscription_create) {
    auto res =
        nodeWrapper->node->create_subscription_vector("ExtraChainSubscription");
    if (res) {
      eSuccess("ExtraChainSubscription created");
      std::exit(0);
    } else {
      eLog("ExtraChainSubscription created: error");
      std::exit(0);
    }
  }
#endif

  QObject::connect(nodeWrapper->node->network(),
                   &NetworkManager::connectionStatusChanged, [](bool status) {
                     static bool prev = false;
                     if (prev == status) {
                       return;
                     }

                     prev = status;
                     if (status) {
                       eInfo("ExtraChain decentralized network is online");
                     } else {
                       eInfo("ExtraChain decentralized network is offline");
                     }
                   });

  QObject::connect(
      nodeWrapper->node, &ExtraChainNode::selfTxAdded,
      [&nodeWrapper](const Transaction &tx, StatusTrx::StatusTrxType status) {
        if (status != StatusTrx::StatusTrxType::Approved) {
          return;
        }

        if (tx.type() == TransactionType::Reward) {
          eInfo("Mining reward: {} ROCC",
                tx.amount().to_string(NumeralBase::Dec));
          return;
        }

        auto actors = nodeWrapper->node->account_controller()->accounts_ids();

        TransactionAmountOperation operation = TransactionAmountOperation::Plus;
        for (const auto &actor : actors) {
          if (actor == tx.sender() &&
              (tx.type() == TransactionType::Regular ||
               tx.type() == TransactionType::Repeatable)) {
            operation = TransactionAmountOperation::Minus;
            break;
          }
        }

        auto op = operation == TransactionAmountOperation::Minus ? "-" : "";
        eInfo("Transaction. Sender: {}, receiver: {}, amount: {}{}",
              tx.sender(), tx.receiver(), op,
              tx.amount().to_string(NumeralBase::Dec));
      });

  SimpleConsole::start([nodeWrapper](const std::string &command) {
    static ConsoleCommandProcessor inputProcessor(*nodeWrapper->node);
    inputProcessor.processInputCommand(command);
  });

  return app.exec();
}
