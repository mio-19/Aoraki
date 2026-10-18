/*
 * Rime Input Method Plugin for Qt Virtual Keyboard & AsteroidOS
 *
 * Upstream: https://github.com/rime/librime
 * Inspiration: https://github.com/fcitx/fcitx5-rime
 */

#include "rimeinputmethod.h"

#include <rime_api.h>
#undef Bool

#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtCore/QLoggingCategory>

namespace QtVirtualKeyboard {

Q_LOGGING_CATEGORY(lcRime, "qt.virtualkeyboard.rime")

RimeInputMethod::RimeInputMethod(QObject *parent)
    : QVirtualKeyboardAbstractInputMethod(parent)
    , m_inputMode(QVirtualKeyboardInputEngine::InputMode::Pinyin)
    , m_currentSchema(QStringLiteral("luna_pinyin"))
{
    initRime();
}

RimeInputMethod::~RimeInputMethod()
{
    if (m_rime && m_session != 0) {
        m_rime->destroy_session(m_session);
        m_session = 0;
    }
}

void RimeInputMethod::initRime()
{
    if (m_initialized)
        return;

    m_rime = rime_get_api();
    if (!m_rime) {
        qCWarning(lcRime) << "Failed to acquire Rime API";
        return;
    }

    // Determine paths
    QString sharedDataDir = qEnvironmentVariable("RIME_SHARED_DATA_DIR");
    if (sharedDataDir.isEmpty() || !QDir(sharedDataDir).exists()) {
        const QStringList searchDirs = {
            QStringLiteral("/run/current-system/sw/share/rime-data"),
            QStringLiteral("/usr/share/rime-data"),
            QDir::homePath() + QStringLiteral("/.local/share/rime-data")
        };
        for (const QString &dir : searchDirs) {
            if (QDir(dir).exists()) {
                sharedDataDir = dir;
                break;
            }
        }
    }

    QString userDataDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/asteroid/rime");
    QDir().mkpath(userDataDir);

    RimeTraits traits;
    RIME_STRUCT_INIT(RimeTraits, traits);
    QByteArray sharedDirBa = sharedDataDir.toUtf8();
    QByteArray userDirBa = userDataDir.toUtf8();
    traits.shared_data_dir = sharedDirBa.constData();
    traits.user_data_dir = userDirBa.constData();
    traits.distribution_name = "Rime";
    traits.distribution_code_name = "AsteroidOS";
    traits.distribution_version = "1.0";
    traits.app_name = "asteroid-virtualkeyboard";

    m_rime->setup(&traits);
    m_rime->initialize(&traits);
    m_rime->start_maintenance(0);

    m_session = m_rime->create_session();
    if (m_session != 0) {
        m_rime->select_schema(m_session, m_currentSchema.toUtf8().constData());
    }

    m_initialized = true;
    qCInfo(lcRime) << "Rime initialized with shared dir:" << sharedDataDir << "user dir:" << userDataDir;
}

QList<QVirtualKeyboardInputEngine::InputMode> RimeInputMethod::inputModes(const QString &locale)
{
    Q_UNUSED(locale);
    return {
        QVirtualKeyboardInputEngine::InputMode::Pinyin,
        QVirtualKeyboardInputEngine::InputMode::Latin
    };
}

bool RimeInputMethod::setInputMode(const QString &locale, QVirtualKeyboardInputEngine::InputMode inputMode)
{
    Q_UNUSED(locale);
    m_inputMode = inputMode;
    reset();
    return true;
}

bool RimeInputMethod::setTextCase(QVirtualKeyboardInputEngine::TextCase textCase)
{
    Q_UNUSED(textCase);
    return true;
}

int RimeInputMethod::translateQtKeyToRime(Qt::Key key, const QString &text) const
{
    switch (key) {
    case Qt::Key_Backspace:
        return 0xff08; // XK_BackSpace
    case Qt::Key_Return:
    case Qt::Key_Enter:
        return 0xff0d; // XK_Return
    case Qt::Key_Space:
        return 0x0020; // XK_space
    case Qt::Key_Escape:
        return 0xff1b; // XK_Escape
    case Qt::Key_Delete:
        return 0xffff; // XK_Delete
    case Qt::Key_Apostrophe:
        return '\'';
    default:
        break;
    }

    if (!text.isEmpty()) {
        QChar ch = text.at(0);
        if (ch.unicode() <= 127) {
            return ch.toLower().toLatin1();
        }
    }

    return 0;
}

bool RimeInputMethod::keyEvent(Qt::Key key, const QString &text, Qt::KeyboardModifiers modifiers)
{
    Q_UNUSED(modifiers);
    if (!m_initialized || !m_rime || m_session == 0)
        return false;

    if (m_inputMode != QVirtualKeyboardInputEngine::InputMode::Pinyin)
        return false;

    // Check if composing
    RimeContext ctx;
    RIME_STRUCT_INIT(RimeContext, ctx);
    bool isComposing = false;
    if (m_rime->get_context(m_session, &ctx)) {
        isComposing = (ctx.composition.length > 0 || ctx.menu.num_candidates > 0);
        m_rime->free_context(&ctx);
    }

    // Space key when candidates exist selects candidate 0
    if (key == Qt::Key_Space) {
        if (isComposing && !m_candidates.isEmpty()) {
            selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type::WordCandidateList, 0);
            return true;
        }
        return false;
    }

    // Number keys 1-9 when composing select candidate by index
    if (isComposing && key >= Qt::Key_1 && key <= Qt::Key_9) {
        int index = key - Qt::Key_1;
        if (index < m_candidates.size()) {
            selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type::WordCandidateList, index);
            return true;
        }
    }

    int keycode = translateQtKeyToRime(key, text);
    if (keycode == 0)
        return false;

    // Process key in Rime
    bool handled = (m_rime->process_key(m_session, keycode, 0) != 0);
    updateContextAndCommit();

    return handled;
}

void RimeInputMethod::updateContextAndCommit()
{
    if (!m_rime || m_session == 0)
        return;

    // 1. Check for committed text
    RimeCommit commit;
    RIME_STRUCT_INIT(RimeCommit, commit);
    if (m_rime->get_commit(m_session, &commit)) {
        if (commit.text && commit.text[0] != '\0') {
            if (inputContext()) {
                inputContext()->commit(QString::fromUtf8(commit.text));
            }
        }
        m_rime->free_commit(&commit);
    }

    // 2. Update context (preedit & candidates)
    RimeContext ctx;
    RIME_STRUCT_INIT(RimeContext, ctx);
    if (m_rime->get_context(m_session, &ctx)) {
        QString preedit = QString::fromUtf8(ctx.composition.preedit);
        if (inputContext()) {
            inputContext()->setPreeditText(preedit);
        }

        m_candidates.clear();
        for (int i = 0; i < ctx.menu.num_candidates; ++i) {
            m_candidates.append(QString::fromUtf8(ctx.menu.candidates[i].text));
        }

        emit selectionListChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidateList);
        emit selectionListsChanged();
        m_rime->free_context(&ctx);
    }
}

QList<QVirtualKeyboardSelectionListModel::Type> RimeInputMethod::selectionLists()
{
    return { QVirtualKeyboardSelectionListModel::Type::WordCandidateList };
}

int RimeInputMethod::selectionListItemCount(QVirtualKeyboardSelectionListModel::Type type)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidateList)
        return m_candidates.size();
    return 0;
}

QVariant RimeInputMethod::selectionListData(QVirtualKeyboardSelectionListModel::Type type, int index,
                                            QVirtualKeyboardSelectionListModel::Role role)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidateList && index >= 0 && index < m_candidates.size()) {
        if (role == QVirtualKeyboardSelectionListModel::Role::Display)
            return m_candidates.at(index);
    }
    return QVariant();
}

void RimeInputMethod::selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type type, int index)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidateList && m_rime && m_session != 0) {
        m_rime->select_candidate(m_session, index);
        updateContextAndCommit();
    }
}

void RimeInputMethod::reset()
{
    if (m_rime && m_session != 0) {
        m_rime->clear_composition(m_session);
    }
    m_candidates.clear();
    if (inputContext()) {
        inputContext()->setPreeditText(QString());
    }
    emit selectionListChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidateList);
    emit selectionListsChanged();
}

void RimeInputMethod::update()
{
    // No-op
}

bool RimeInputMethod::selectSchema(const QString &schemaId)
{
    if (!m_rime || m_session == 0)
        return false;

    QByteArray schemaBa = schemaId.toUtf8();
    bool ok = (m_rime->select_schema(m_session, schemaBa.constData()) != 0);
    if (ok) {
        m_currentSchema = schemaId;
        reset();
        emit schemaChanged(m_currentSchema);
        qCInfo(lcRime) << "Selected Rime schema:" << schemaId;
        return true;
    }
    return false;
}

QString RimeInputMethod::currentSchema() const
{
    return m_currentSchema;
}

QStringList RimeInputMethod::availableSchemas() const
{
    return {
        QStringLiteral("luna_pinyin"),
        QStringLiteral("double_pinyin"),
        QStringLiteral("double_pinyin_flypy"),
        QStringLiteral("wubi86"),
        QStringLiteral("cangjie5"),
        QStringLiteral("stroke"),
        QStringLiteral("bopomofo"),
        QStringLiteral("jyutping")
    };
}

} // namespace QtVirtualKeyboard
