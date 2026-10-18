/*
 * Rime Input Method Plugin for Qt Virtual Keyboard & AsteroidOS
 *
 * Upstream: https://github.com/rime/librime
 * Inspiration: https://github.com/fcitx/fcitx5-rime
 */

#pragma once

#include <QtVirtualKeyboard/qvirtualkeyboardabstractinputmethod.h>
#include <QtVirtualKeyboard/qvirtualkeyboardinputcontext.h>
#include <QtVirtualKeyboard/qvirtualkeyboardinputengine.h>
#include <QtQml/qqml.h>
#include <QtCore/QStringList>
#include <QtCore/QPointer>

typedef struct rime_api_t RimeApi;

namespace QtVirtualKeyboard {

class RimeInputMethod : public QVirtualKeyboardAbstractInputMethod
{
    Q_OBJECT
    QML_ELEMENT
    QML_ADDED_IN_VERSION(1, 0)
    Q_PROPERTY(QString currentSchema READ currentSchema WRITE selectSchema NOTIFY schemaChanged)
    Q_PROPERTY(QStringList availableSchemas READ availableSchemas CONSTANT)

public:
    explicit RimeInputMethod(QObject *parent = nullptr);
    ~RimeInputMethod() override;

    QList<QVirtualKeyboardInputEngine::InputMode> inputModes(const QString &locale) override;
    bool setInputMode(const QString &locale, QVirtualKeyboardInputEngine::InputMode inputMode) override;
    bool setTextCase(QVirtualKeyboardInputEngine::TextCase textCase) override;

    bool keyEvent(Qt::Key key, const QString &text, Qt::KeyboardModifiers modifiers) override;

    QList<QVirtualKeyboardSelectionListModel::Type> selectionLists() override;
    int selectionListItemCount(QVirtualKeyboardSelectionListModel::Type type) override;
    QVariant selectionListData(QVirtualKeyboardSelectionListModel::Type type, int index,
                               QVirtualKeyboardSelectionListModel::Role role) override;
    void selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type type, int index) override;

    void reset() override;
    void update() override;

    Q_INVOKABLE bool selectSchema(const QString &schemaId);
    Q_INVOKABLE QString currentSchema() const;
    Q_INVOKABLE QStringList availableSchemas() const;

Q_SIGNALS:
    void schemaChanged(const QString &schemaId);

private:
    void initRime();
    void updateContextAndCommit();
    int translateQtKeyToRime(Qt::Key key, const QString &text) const;

    RimeApi *m_rime = nullptr;
    uintptr_t m_session = 0;
    QStringList m_candidates;
    QString m_currentSchema;
    QVirtualKeyboardInputEngine::InputMode m_inputMode;
    bool m_initialized = false;
};

} // namespace QtVirtualKeyboard
