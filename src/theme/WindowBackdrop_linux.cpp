#include <QGuiApplication>
#include <QWindow>

#if defined(DRIFT_HAS_KF6_WINDOW_SYSTEM)
#include <KWindowEffects>
#endif

#if defined(DRIFT_HAS_XCB)
#include <xcb/xcb.h>

#include <QtGui/qguiapplication_platform.h>

#include <cstdlib>
#include <cstring>
#endif

namespace drift::backdrop {

namespace {

#if defined(DRIFT_HAS_XCB) && QT_CONFIG(xcb)
xcb_atom_t blurAtom(xcb_connection_t *connection)
{
    static xcb_atom_t atom = XCB_ATOM_NONE;
    static bool lookedUp = false;
    if (lookedUp)
        return atom;
    lookedUp = true;
    const char *name = "_KDE_NET_WM_BLUR_BEHIND_REGION";
    xcb_intern_atom_cookie_t cookie = xcb_intern_atom(connection, 0, std::strlen(name), name);
    xcb_intern_atom_reply_t *reply = xcb_intern_atom_reply(connection, cookie, nullptr);
    if (!reply)
        return XCB_ATOM_NONE;
    atom = reply->atom;
    free(reply);
    return atom;
}

void setX11Blur(QWindow *window, bool enable)
{
    if (QGuiApplication::platformName() != QLatin1String("xcb"))
        return;
    auto *x11 = qApp->nativeInterface<QNativeInterface::QX11Application>();
    if (!x11)
        return;
    xcb_connection_t *connection = x11->connection();
    if (!connection)
        return;
    const xcb_atom_t atom = blurAtom(connection);
    if (atom == XCB_ATOM_NONE)
        return;

    const xcb_window_t xid = static_cast<xcb_window_t>(window->winId());
    if (enable) {
        // A zero-length CARDINAL region is the KWin convention for "the whole window".
        xcb_change_property(connection, XCB_PROP_MODE_REPLACE, xid, atom, XCB_ATOM_CARDINAL, 32, 0,
                            nullptr);
    } else {
        xcb_delete_property(connection, xid, atom);
    }
    xcb_flush(connection);
}
#endif

} // namespace

void applyNative(QWindow *window, const QString &backdrop, bool /*darkVariant*/)
{
    if (!window)
        return;
    const bool blur = backdrop == QLatin1String("blur");

#if defined(DRIFT_HAS_KF6_WINDOW_SYSTEM)
    // Covers KWin on X11 and Wayland (org_kde_kwin_blur). A null region is the
    // whole window. Other compositors ignore the request; the window is still
    // translucent and their own rules can blur it.
    KWindowEffects::enableBlurBehind(window, blur);
    if (KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind))
        return;
#endif

#if defined(DRIFT_HAS_XCB) && QT_CONFIG(xcb)
    // X11 fallback when KWindowSystem is not linked, or when it is linked but
    // this session has no KWin blur effect (the atom is what KWin and some
    // other X11 compositors actually watch).
    setX11Blur(window, blur);
#else
    Q_UNUSED(blur);
#endif

    // Wayland protocols other than KWin's (ext-background-effect, wlr-layer blur)
    // are not spoken here. Hyprland, Sway, and GNOME decide blur from compositor
    // rules keyed on the app id org.cutwire.Drift; transparency is the app's part.
}

} // namespace drift::backdrop
