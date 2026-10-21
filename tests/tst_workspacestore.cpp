#include <QtTest>

#include <QSettings>
#include <QStandardPaths>

#include "app/editor/WorkspaceStore.h"

class WorkspaceStoreTest : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void presetsLoadAndValidate();
    void everyBuiltinPresetValidates();
    void roundTripAndOverride();
    void rejectsDuplicatePanels();
    void acceptsTabPanelTypes();
    void sizesAreNormalizedAndSplitCollapses();
    void setSizesIsQuiet();
    void duplicateAndRemove();
    void migratesOldFractions();

private:
    QString m_org;
    QString m_app;
};

namespace {

QVariantMap slot(const QString &type)
{
    return {{"panels", QVariantList{QVariantMap{{"type", type}}}}, {"active", 0}};
}

QVariantMap workspaceWith(const QVariantMap &root, const QString &id = {})
{
    return {{"id", id},
            {"name", "Test"},
            {"windows", QVariantList{QVariantMap{{"id", "main"}, {"root", root}}}}};
}

QVariantMap mainRoot(const QVariantMap &ws)
{
    return ws.value("windows").toList().first().toMap().value("root").toMap();
}

} // namespace

void WorkspaceStoreTest::init()
{
    m_org = QCoreApplication::organizationName();
    m_app = QCoreApplication::applicationName();
    QStandardPaths::setTestModeEnabled(true);
    QCoreApplication::setOrganizationName(QStringLiteral("DriftTest"));
    QCoreApplication::setApplicationName(QStringLiteral("DriftTest"));
    QSettings().remove(QStringLiteral("ui"));
}

void WorkspaceStoreTest::cleanup()
{
    QSettings().remove(QStringLiteral("ui"));
    QCoreApplication::setOrganizationName(m_org);
    QCoreApplication::setApplicationName(m_app);
}

void WorkspaceStoreTest::presetsLoadAndValidate()
{
    WorkspaceStore store;
    const QVariantList list = store.workspaces();
    QCOMPARE(list.size(), 8);
    QCOMPARE(list.at(0).toMap().value("id").toString(), QStringLiteral("edit"));
    QCOMPARE(list.at(1).toMap().value("id").toString(), QStringLiteral("edit-portrait"));
    for (const QVariant &v : list)
        QCOMPARE(store.validate(v.toMap()), QString());
    QCOMPARE(store.activeId(), QStringLiteral("edit"));
}

void WorkspaceStoreTest::everyBuiltinPresetValidates()
{
    WorkspaceStore store;
    int builtins = 0;
    for (const QVariant &v : store.workspaces()) {
        const QVariantMap ws = v.toMap();
        if (!ws.value("builtin").toBool())
            continue;
        ++builtins;
        QCOMPARE(store.validate(ws), QString());
    }
    QCOMPARE(builtins, 8);
}

void WorkspaceStoreTest::roundTripAndOverride()
{
    WorkspaceStore store;
    QSignalSpy edited(&store, &WorkspaceStore::activeWorkspaceEdited);
    QVariantMap ws = store.workspace("edit");
    ws["name"] = "Mine";
    QCOMPARE(store.saveWorkspace(ws), QString());
    QCOMPARE(edited.count(), 1);

    WorkspaceStore reloaded;
    const QVariantMap again = reloaded.workspace("edit");
    QCOMPARE(again.value("name").toString(), QStringLiteral("Mine"));
    QVERIFY(again.value("modified").toBool());
    QVERIFY(again.value("builtin").toBool());
    QCOMPARE(reloaded.workspaces().size(), 8);

    reloaded.resetPreset("edit");
    QCOMPARE(reloaded.workspace("edit").value("name").toString(), QStringLiteral("Edit"));
}

void WorkspaceStoreTest::rejectsDuplicatePanels()
{
    WorkspaceStore store;
    const QVariantMap root{{"split", "h"},
                           {"children", QVariantList{slot("preview"), slot("preview")}}};
    QVERIFY(!store.saveWorkspace(workspaceWith(root)).isEmpty());
    QVERIFY(!store.saveWorkspace(workspaceWith(slot("bogus"))).isEmpty());
    QCOMPARE(store.workspaces().size(), 8);
}

void WorkspaceStoreTest::acceptsTabPanelTypes()
{
    WorkspaceStore store;
    const QVariantMap ok{{"split", "h"},
                         {"children", QVariantList{slot("assets.effects"), slot("properties.transform"),
                                                   slot("assets")}}};
    QCOMPARE(store.validate(workspaceWith(ok)), QString());
    const QVariantMap dup{{"split", "h"},
                          {"children", QVariantList{slot("assets.effects"), slot("assets.effects")}}};
    QVERIFY(!store.validate(workspaceWith(dup)).isEmpty());
    QVERIFY(!store.validate(workspaceWith(slot("assets.nope"))).isEmpty());

    int tabTypes = 0;
    for (const QVariant &v : store.panelTypes()) {
        const QVariantMap t = v.toMap();
        if (t.value("group").toString() == "panel")
            continue;
        ++tabTypes;
        QVERIFY(t.value("type").toString().startsWith(t.value("group").toString() + "."));
        QVERIFY(!t.value("tab").toString().isEmpty());
    }
    QCOMPARE(tabTypes, 31);
}

void WorkspaceStoreTest::sizesAreNormalizedAndSplitCollapses()
{
    WorkspaceStore store;
    const QVariantMap root{{"split", "h"},
                           {"children", QVariantList{slot("preview"), slot("timeline")}},
                           {"sizes", QVariantList{1.0}}};
    QCOMPARE(store.saveWorkspace(workspaceWith(root, "custom-x")), QString());
    const QVariantList sizes = mainRoot(store.workspace("custom-x")).value("sizes").toList();
    QCOMPARE(sizes.size(), 2);
    QCOMPARE(sizes.at(0).toDouble(), 0.5);

    const QVariantMap single{{"split", "v"}, {"children", QVariantList{slot("preview")}}};
    QCOMPARE(store.saveWorkspace(workspaceWith(single, "custom-y")), QString());
    QVERIFY(mainRoot(store.workspace("custom-y")).contains("panels"));
}

void WorkspaceStoreTest::setSizesIsQuiet()
{
    WorkspaceStore store;
    QSignalSpy edited(&store, &WorkspaceStore::activeWorkspaceEdited);
    QSignalSpy changed(&store, &WorkspaceStore::workspacesChanged);
    store.setSizes("edit", "main", {0}, {1.0, 2.0, 1.0});
    QCOMPARE(edited.count(), 0);
    QCOMPARE(changed.count(), 0);

    WorkspaceStore reloaded;
    const QVariantMap row = mainRoot(reloaded.workspace("edit")).value("children").toList().first().toMap();
    QCOMPARE(row.value("sizes").toList().at(1).toDouble(), 0.5);
    QVERIFY(reloaded.workspace("edit").value("modified").toBool());
}

void WorkspaceStoreTest::duplicateAndRemove()
{
    WorkspaceStore store;
    const QString id = store.duplicate("edit");
    QVERIFY(!id.isEmpty());
    QVERIFY(!store.workspace(id).value("builtin").toBool());
    QVERIFY(!store.remove("edit"));
    store.setActiveId(id);
    QCOMPARE(store.activeId(), id);
    QVERIFY(store.remove(id));
    QCOMPARE(store.activeId(), QStringLiteral("edit"));
}

void WorkspaceStoreTest::migratesOldFractions()
{
    QSettings settings;
    settings.setValue("ui/layout/landscape/assets", 0.2);
    settings.setValue("ui/layout/landscape/properties", 0.3);
    settings.setValue("ui/layout/landscape/editorRow", 0.6);
    settings.setValue("ui/layout/portrait/preview", 0.3);

    WorkspaceStore store;
    const QVariantMap root = mainRoot(store.workspace("edit"));
    QCOMPARE(root.value("sizes").toList().at(0).toDouble(), 0.6);
    const QVariantList row = root.value("children").toList().first().toMap().value("sizes").toList();
    QCOMPARE(row.at(0).toDouble(), 0.2);
    QCOMPARE(row.at(2).toDouble(), 0.3);
    QVERIFY(store.workspace("edit").value("modified").toBool());

    const QVariantMap portrait = mainRoot(store.workspace("edit-portrait"));
    QCOMPARE(portrait.value("sizes").toList().at(1).toDouble(), 0.3);
    QVERIFY(settings.contains("ui/workspaces/list"));
    QVERIFY(settings.contains("ui/layout/landscape/assets"));
}

QTEST_MAIN(WorkspaceStoreTest)
#include "tst_workspacestore.moc"
