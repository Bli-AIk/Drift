#pragma once

#include "core/project/SubtitleCue.h"

#include <QAbstractListModel>
#include <QList>

// The selected subtitle clip's cues as a list model, so delegates bind to roles instead of a
// QVariantList that allocates a JS object on every index. Times are clip-local seconds.
class SubtitleCueModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        StartRole = Qt::UserRole + 1,
        EndRole,
        TextRole,
        SourceRole,
    };

    explicit SubtitleCueModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Same row count: dataChanged for the rows that differ. Otherwise a reset. Nothing at all
    // when the cues are identical.
    void setCues(const QList<drift::SubtitleCue> &cues);

private:
    QList<drift::SubtitleCue> m_cues;
};
