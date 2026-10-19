// qt_windows.h defines WIN32_LEAN_AND_MEAN and NOMINMAX before windows.h.
// Those have to win the first include: a later NOMINMAX does not undo the
// min/max macros, and that breaks the Qt headers on both MSVC and MinGW.
#include <QtCore/qt_windows.h>
#include <dwmapi.h>

#include <QOperatingSystemVersion>
#include <QWindow>

namespace drift::backdrop {

namespace {

// Documented in DWMWINDOWATTRIBUTE. Defined locally so an older Windows SDK
// that predates 22H2 still compiles; the calls fail at runtime there and the
// accent-policy fallback below is what Windows 10 actually uses.
constexpr DWORD kUseImmersiveDarkMode = 20; // DWMWA_USE_IMMERSIVE_DARK_MODE
constexpr DWORD kSystemBackdropType = 38;   // DWMWA_SYSTEMBACKDROP_TYPE
constexpr int kBackdropNone = 1;            // DWMSBT_NONE
constexpr int kBackdropMainWindow = 2;      // DWMSBT_MAINWINDOW (Mica)
constexpr int kBackdropTransient = 3;       // DWMSBT_TRANSIENTWINDOW (Acrylic)

constexpr int kAccentDisabled = 0;
constexpr int kAccentBlurBehind = 3;         // ACCENT_ENABLE_BLURBEHIND
constexpr int kAccentAcrylicBlurBehind = 4;  // ACCENT_ENABLE_ACRYLICBLURBEHIND
constexpr int kAccentPolicyAttribute = 19;   // WCA_ACCENT_POLICY

struct AccentPolicy {
    int state;
    int flags;
    DWORD gradientColor; // AABBGGRR
    int animationId;
};

struct WindowCompositionAttributeData {
    int attribute;
    void *data;
    SIZE_T dataSize;
};

using SetWindowCompositionAttributeFn = BOOL(WINAPI *)(HWND, WindowCompositionAttributeData *);

SetWindowCompositionAttributeFn compositionAttributeFn()
{
    static SetWindowCompositionAttributeFn fn = [] {
        HMODULE user32 = GetModuleHandleW(L"user32.dll");
        if (!user32)
            return static_cast<SetWindowCompositionAttributeFn>(nullptr);
        return reinterpret_cast<SetWindowCompositionAttributeFn>(
            GetProcAddress(user32, "SetWindowCompositionAttribute"));
    }();
    return fn;
}

void setAccent(HWND hwnd, int state, DWORD gradientColor)
{
    SetWindowCompositionAttributeFn fn = compositionAttributeFn();
    if (!fn)
        return;
    AccentPolicy policy{};
    policy.state = state;
    policy.gradientColor = gradientColor;
    WindowCompositionAttributeData data{};
    data.attribute = kAccentPolicyAttribute;
    data.data = &policy;
    data.dataSize = sizeof(policy);
    fn(hwnd, &data);
}

void setBackdropType(HWND hwnd, int type)
{
    DwmSetWindowAttribute(hwnd, kSystemBackdropType, &type, sizeof(type));
}

void extendFrame(HWND hwnd, bool enable)
{
    MARGINS margins{};
    if (enable) {
        margins.cxLeftWidth = -1;
        margins.cxRightWidth = -1;
        margins.cyTopHeight = -1;
        margins.cyBottomHeight = -1;
    }
    DwmExtendFrameIntoClientArea(hwnd, &margins);
}

bool windows11_22H2()
{
    return QOperatingSystemVersion::current() >= QOperatingSystemVersion::Windows11_22H2;
}

DWORD acrylicTint(bool darkVariant)
{
    // High alpha so the tint does not wash the theme color the Qt window already draws.
    return darkVariant ? 0x66000000u : 0x66FFFFFFu;
}

} // namespace

void applyNative(QWindow *window, const QString &backdrop, bool darkVariant)
{
    if (!window)
        return;
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd)
        return;

    const BOOL dark = darkVariant ? TRUE : FALSE;
    DwmSetWindowAttribute(hwnd, kUseImmersiveDarkMode, &dark, sizeof(dark));

    const bool win11 = windows11_22H2();
    if (backdrop == QLatin1String("mica") && win11) {
        setAccent(hwnd, kAccentDisabled, 0);
        extendFrame(hwnd, true);
        setBackdropType(hwnd, kBackdropMainWindow);
        return;
    }
    if (backdrop == QLatin1String("acrylic") && win11) {
        setAccent(hwnd, kAccentDisabled, 0);
        extendFrame(hwnd, true);
        setBackdropType(hwnd, kBackdropTransient);
        return;
    }
    if (backdrop == QLatin1String("acrylic")) {
        // Windows 10 (and Windows 11 before 22H2): undocumented but stable accent blur.
        if (win11)
            setBackdropType(hwnd, kBackdropNone);
        extendFrame(hwnd, true);
        setAccent(hwnd, kAccentAcrylicBlurBehind, acrylicTint(darkVariant));
        return;
    }
    if (backdrop == QLatin1String("blur")) {
        if (win11)
            setBackdropType(hwnd, kBackdropNone);
        extendFrame(hwnd, true);
        setAccent(hwnd, kAccentBlurBehind, 0);
        return;
    }

    setAccent(hwnd, kAccentDisabled, 0);
    if (win11)
        setBackdropType(hwnd, kBackdropNone);
    extendFrame(hwnd, false);
}

} // namespace drift::backdrop
