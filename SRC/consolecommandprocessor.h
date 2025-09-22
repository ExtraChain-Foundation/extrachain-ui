#ifndef CONSOLECOMMANDPROCESSOR_H
#define CONSOLECOMMANDPROCESSOR_H

#include <QObject>
#include "managers/extrachain_node.h"
#include "dfs/dfs_utils.h"

class ConsoleCommandProcessor : public QObject {
    Q_OBJECT

    ExtraChainNode& node;

public:
    explicit ConsoleCommandProcessor(ExtraChainNode& _node, QObject* parent = nullptr);

    void processInputCommand(const std::string& input);

private:
    void showWalletsList(const std::string& input);
    void showSectionsCount(const std::string& input);
    void showDfsSize(const std::string& input);
    void sendDfsAdd(const std::string& input);
    void sendDfsRemove(const std::string& input);
    void sendWalletTransfer(const std::string& input);
    void showHelp();
    void sendWalletAdd(const std::string& input);
    void sendWalletRename(const std::string& input);
    void exportProfileFile(const std::string& input);
    void exportProfilePhrase(const std::string& input);
    void exportProfileHex(const std::string& input);

    std::vector<std::string> getExpectedArgument(const std::string& input,
                                                 const std::string& command,
                                                 std::size_t        expected_arg_count);
    std::string              getFileName(const std::string& file_path);
    std::string              getErrorMessage(Dfs::DfsError error);
};

#endif // CONSOLECOMMANDPROCESSOR_H
