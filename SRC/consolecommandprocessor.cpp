#include "consolecommandprocessor.h"
#include "chain/dag.h"
#include "dfs/dfs_controller.h"

#include "chain/private_profile.h"
#include <filesystem>

static std::mutex coutMutex;

ConsoleCommandProcessor::ConsoleCommandProcessor(ExtraChainNode &_node,
                                                 QObject *parent)
    : node(_node), QObject(parent) {}

void ConsoleCommandProcessor::processInputCommand(const std::string &input) {
  QString command = QString::fromStdString(input).trimmed().simplified();

  if (command == "wallet list") {
    showWalletsList(command.toStdString());
  } else if (command == "section count") {
    showSectionsCount(command.toStdString());
  } else if (command == "dfs count size") {
    showDfsSize(command.toStdString());
  } else if (command == "help") {
    showHelp();
    // section get
  } else if (command.startsWith("dfs add")) {
    sendDfsAdd(command.toStdString());
  } else if (command.startsWith("dfs remove")) {
    sendDfsRemove(command.toStdString());
  } else if (command.startsWith("wallet transfer")) {
    sendWalletTransfer(command.toStdString());
  } else if (command.startsWith("wallet add")) {
    sendWalletAdd(command.toStdString());
  } else if (command.startsWith("wallet rename")) {
    sendWalletRename(command.toStdString());
  } else if (command.startsWith("export file")) {
    exportProfileFile(command.toStdString());
  } else if (command.startsWith("export phrase")) {
    exportProfilePhrase(command.toStdString());
  } else if (command.startsWith("export hex")) {
    exportProfileHex(command.toStdString());
  } else if (command == "quit" || command == "exit") {
    qApp->quit();
  } else {
    eInfo("Incorrect command: \"{}\"", command.toStdString());
  }
  // dfs list
  // section id
  // wallet txs <wallet>
}

void ConsoleCommandProcessor::showWalletsList(const std::string &input) {
  const auto &actors = node.account_controller()->accounts_ids();
  const auto &balances = node.dag()->calculate_actors_balance(actors);
  if (balances.empty()) {
    for (const auto &actor : actors) {
      eInfo("{} 0 ROCC", actor);
    }
    return;
  } else {
    // const auto&        wallets_names =
    // node.accountController()->currentProfile().wallet_names();
    for (const auto &[pair, balance] :
         balances) { // TODO: use one for for actors
      // const auto& name = wallets_names.find(wallet.first);
      // if (name != wallets_names.end()) {
      //     output << name->second << " ";
      // }
      const auto &amount = balance.to_string(NumeralBase::Dec);
      size_t pos = amount.find(".");
      if (pos == std::string::npos && !pair.second.is_zero()) {
        eInfo("{} {} ROCC", pair.first.to_string(),
              balance.to_string(NumeralBase::Dec));
      } else {
        eInfo("{} {} ROCC", pair.first.to_string(),
              balance.to_string(NumeralBase::Dec).substr(0, pos + 5));
      }
    }
  }
}

void ConsoleCommandProcessor::showSectionsCount(const std::string &input) {
  eInfo("Sections count: {}",
        node.dag()->current_section().to_string(NumeralBase::Dec));
}

void ConsoleCommandProcessor::showDfsSize(const std::string &input) {
  eInfo("Total dfs size: {}", node.dfs()->totalDfsSize());
}

void ConsoleCommandProcessor::showHelp() {
  eInfo("Available commands:");
  eInfo("  wallet list                          : List of available wallets");
  eInfo("  section count                        : Show the number of sections");
  eInfo("  dfs count size                       : Show the total Dfs size");
  eInfo("  section get <id>                     : Retrieve section information "
        "by id");
  eInfo("  dfs add <file_path>                  : Add a file to the Dfs");
  eInfo("  dfs remove <file_id>                 : Remove a file from the Dfs");
  eInfo("  wallet transfer <from> <to> <amount> : Transfer funds between "
        "wallets");
  eInfo("  export file <folder>                 : Export profile");
  eInfo("  export phrase                        : Export mnemonic phrase");
  eInfo("  export hex                           : Export hex");
  eInfo("  exit quit                            : Exit the application");
  eInfo("  help                                 : Show this help message");
}

void ConsoleCommandProcessor::sendDfsAdd(const std::string &input) {
  std::vector<std::string> arguments = getExpectedArgument(input, "dfs add", 1);
  if (arguments.empty()) {
    return;
  }
  const std::string &file_path = arguments.at(0);
  const std::string &file_name = getFileName(file_path);

  auto mainId = node.account_controller()->current_profile().main_id();
  auto dataSecurity = Dfs::DataSecuritySelf{.my_actor = mainId};

  const auto &result =
      node.dfs()->store_file(mainId, mainId, file_path, "", file_name,
                             Dfs::DataSecurity::Self, dataSecurity);
  eInfo("File path: {}", file_path);
  eInfo("File name: {}", file_name);
  if (result.has_value()) {
    // Dfs::DirRow row = result.value(); //TODO Output
    eInfo("File: {} added successfully", file_name);
  } else {
    eInfo("Failed to add file: {}, error: {}", file_name,
          getErrorMessage(result.error()));
  }
}

void ConsoleCommandProcessor::sendDfsRemove(const std::string &input) {
  std::vector<std::string> arguments =
      getExpectedArgument(input, "dfs remove", 1);
  if (arguments.empty()) {
    return;
  }
  const std::string &file_id = arguments.at(0);
  const auto &result = node.dfs()->remove_stored_file(
      node.account_controller()->system_actor().id(), file_id);

  if (!result) {
    eInfo("Failed to remove file: {}", file_id);
  } else {
    eInfo("File: {} deleted successfully", file_id);
  }
}

void ConsoleCommandProcessor::sendWalletTransfer(const std::string &input) {
  std::vector<std::string> arguments =
      getExpectedArgument(input, "wallet transfer", 3);
  if (arguments.empty()) {
    return;
  }
  const auto &result = node.create_transaction_from(
      ActorId{arguments.at(0)}, ActorId{arguments.at(1)},
      BigNumberFloat{arguments.at(2)},
      ActorId("468faf2f1be6504a9a26f7f027f7e43380b0d77d"));

  if (result) {
    Transaction tx = result.value();
    node.network()->send_message(tx, MessageType::DagTransaction,
                                 SendMode::Broadcast);
    eInfo("Transaction sent");
  } else {
    eInfo("Can not create transaction");
  }
}
void ConsoleCommandProcessor::sendWalletAdd(const std::string &input) {
  if (input == "wallet add") // Check if Wallet Name was NOT provided
  {
    const auto &result = node.account_controller()->create_wallet(
        node.account_controller()->system_actor().id(), "");
    eInfo("Wallet created successfully.\nAddress: {}", result.id().to_string());
    return;
  }
  std::vector<std::string> arguments =
      getExpectedArgument(input, "wallet add", 1);
  if (arguments.empty()) {
    eInfo("Wallet was not created");
    return;
  }
  const auto &result = node.account_controller()->create_wallet(
      node.account_controller()->system_actor().id(), arguments.at(0));
  eInfo("Wallet created successfully.\nAddress: {}\nName: {}",
        result.id().to_string(), arguments.at(0));
}

void ConsoleCommandProcessor::sendWalletRename(const std::string &input) {
  std::vector<std::string> arguments =
      getExpectedArgument(input, "wallet rename", 2);
  if (arguments.empty()) {
    return;
  }

  bool res = node.account_controller()->rename_wallet(
      ActorId{}, ActorId{arguments.at(0)}, arguments.at(1));

  if (res) {
    eInfo("Wallet renamed successfully");
  }
}

void ConsoleCommandProcessor::exportProfileFile(const std::string &input) {
  std::vector<std::string> arguments =
      getExpectedArgument(input, "export file", 1);
  if (arguments.empty()) {
    eInfo("Need folder");
    return;
  }

  auto exported_result = node.export_profile();

  if (!exported_result.has_value()) {
    eInfo("Can't export profile, error: {}", exported_result.error());
  }

  QString folder = QString::fromStdString(arguments[0]);
  // if (folder.last(1) == "/")

  QDateTime now = QDateTime::currentDateTime();
  QString fileName =
      QString("ExtraChain_%1.profile").arg(now.toString("yyyy_MM_dd_hh_mm_ss"));
  QFile file(folder + "/" + fileName);
  if (!file.open(QFile::WriteOnly)) {
    eInfo("Can't open {}", folder + "/" + fileName);
    return;
  }
  file.write(QByteArray::fromStdString(exported_result.value()));
  file.close();

  eInfo("Exported profile to file {}", fileName);
}

void ConsoleCommandProcessor::exportProfilePhrase(const std::string &input) {
  if (node.account_controller()->profile_type() == ProfileType::Old) {
    eInfo("Please, use export file <file>");
    return;
  }

  eInfo("Mnemonic phrase: {}",
        fmt::join(node.account_controller()->seed_mnemonic(), " "));
}

void ConsoleCommandProcessor::exportProfileHex(const std::string &input) {
  if (node.account_controller()->profile_type() == ProfileType::Old) {
    eInfo("Please, use export file <file>");
    return;
  }

  eInfo("Hex (encrypted with login and password): {}",
        node.account_controller()->seed_hex());
}

std::vector<std::string>
ConsoleCommandProcessor::getExpectedArgument(const std::string &input,
                                             const std::string &command,
                                             std::size_t expected_arg_count) {
  std::istringstream iss(input.substr(command.size()));
  std::string word;
  std::vector<std::string> words_after_command;
  while (iss >> word) {
    words_after_command.emplace_back(word);
  }
  if (words_after_command.size() == expected_arg_count) {
    return words_after_command;
  } else if (words_after_command.empty()) {
    eInfo("Arguments were not provided");
  } else {
    eInfo("<{}> expects {} argument(s). {} were provided", command,
          expected_arg_count, words_after_command.size());
  }
  return {};
}

std::string ConsoleCommandProcessor::getFileName(const std::string &file_path) {
  std::filesystem::path p(file_path);
  return p.filename().string();
}

std::string ConsoleCommandProcessor::getErrorMessage(Dfs::DfsError error) {
  switch (error) {
  case Dfs::DfsError::Unknown:
    return "Unknown error occurred.";
  case Dfs::DfsError::NotExists:
    return "The specified file or directory does not exist.";
  case Dfs::DfsError::NotFile:
    return "The specified path is not a file.";
  case Dfs::DfsError::NotReadable:
    return "The file is not readable.";
  case Dfs::DfsError::StorageFull:
    return "The storage is full.";
  case Dfs::DfsError::AlreadyExists:
    return "The file already exists.";
  case Dfs::DfsError::DirError:
    return "There was an error with the directory.";
  case Dfs::DfsError::DirValueNotExists:
    return "The directory value does not exist.";
  case Dfs::DfsError::DirDuplicate:
    return "Duplicate directory entry detected.";
  case Dfs::DfsError::CollectionCreationError:
    return "Failed to create the collection.";
  case Dfs::DfsError::InvalidName:
    return "The provided name is invalid.";
  case Dfs::DfsError::InvalidTemplate:
    return "The provided template is invalid.";
  case Dfs::DfsError::NotWritable:
    return "The file is not writable.";
  case Dfs::DfsError::WrongTemplate:
    return "The wrong template was provided.";
  case Dfs::DfsError::IncorrectSecurityData:
    return "The security data is incorrect.";
  case Dfs::DfsError::IncorrectEncryption:
    return "The encryption is incorrect.";
  case Dfs::DfsError::NoOwnerActor:
    return "No owner actor was provided.";
  case Dfs::DfsError::NoAuthorActor:
    return "No author actor was provided.";
  case Dfs::DfsError::MaxFileSize:
    return "The file exceeds the maximum allowed size.";
  default:
    return "Unrecognized error code.";
  }
}
