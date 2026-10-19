#pragma once

#include <QObject>

// Whether a mouse (or a touchpad driving a pointer) is attached. Android only: the touch shell
// uses it to offer the desktop layout. Always false elsewhere, where the desktop shell is the
// default anyway. The device list lives in android/src/org/cutwire/drift/PointerDevices.java.
namespace drift {

class PointerDevices : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool mousePresent READ mousePresent NOTIFY mousePresentChanged FINAL)

public:
    explicit PointerDevices(QObject *parent = nullptr);

    bool mousePresent() const { return m_mousePresent; }

signals:
    void mousePresentChanged();

private:
    // Invokable so the JNI callback can queue it onto this object's thread.
    Q_INVOKABLE void setMousePresent(bool present);

    bool m_mousePresent = false;
};

} // namespace drift
