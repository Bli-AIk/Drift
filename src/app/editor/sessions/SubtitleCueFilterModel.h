#pragma once

#include <QSortFilterProxyModel>

// SubtitleCueModel narrowed to the cues whose text contains filterText. The cueIndex role is the
// row in the source model, so selection and edits keep addressing the unfiltered list.
class SubtitleCueFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        CueIndexRole = Qt::UserRole + 100,
        OverlapsNextRole,
    };

    explicit SubtitleCueFilterModel(QObject *parent = nullptr);

    void setSourceModel(QAbstractItemModel *model) override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);
    int count() const { return m_count; }

    Q_INVOKABLE int rowForCue(int cueIndex) const;
    Q_INVOKABLE int cueAt(int row) const;

signals:
    void filterTextChanged();
    void countChanged();

private:
    void updateCount();

    QString m_filterText;
    int m_count = 0;
};
