#include "WindowBackdrop.h"

#include <QHash>
#include <QWindow>

#import <AppKit/AppKit.h>

namespace drift::backdrop {

namespace {

// QHash copies values with memcpy. An Objective-C object pointer is a
// retaining type under ARC and cannot live in that container, so the hash
// holds a void* that owns one retain. CMake does not pass -fobjc-arc (the
// OBJCXX language is enabled with the project C++ standard only), so the
// non-ARC branch is what the macOS target compiles. The ARC branch is kept
// so turning ARC on later does not message a view the superview already
// released: the window destructor tears the NSView hierarchy down before
// QObject::destroyed runs.
QHash<QWindow *, void *> g_effects;

void *retainNewEffect(NSVisualEffectView *effect)
{
#if __has_feature(objc_arc)
    return (__bridge_retained void *)effect;
#else
    return effect; // +1 from alloc
#endif
}

NSVisualEffectView *effectFromStored(void *raw)
{
    if (!raw)
        return nil;
#if __has_feature(objc_arc)
    return (__bridge NSVisualEffectView *)raw;
#else
    return static_cast<NSVisualEffectView *>(raw);
#endif
}

void clearEffect(QWindow *window)
{
    void *raw = g_effects.take(window);
    if (!raw)
        return;
    NSVisualEffectView *effect = nil;
#if __has_feature(objc_arc)
    effect = (__bridge_transfer NSVisualEffectView *)raw;
#else
    effect = static_cast<NSVisualEffectView *>(raw);
#endif
    if (effect.superview)
        [effect removeFromSuperview];
#if !__has_feature(objc_arc)
    [effect release];
#endif
}

NSVisualEffectMaterial materialFor(const QString &backdrop)
{
    // vibrancy is the system window material; blur is the heavier HUD blur.
    // Appearance (below) follows the theme variant, so each material has a
    // dark and a light form.
    if (backdrop == QLatin1String("blur"))
        return NSVisualEffectMaterialHUDWindow;
    return NSVisualEffectMaterialUnderWindowBackground;
}

void trackWindow(QWindow *window)
{
    if (window->property("_driftBackdropTracked").toBool())
        return;
    window->setProperty("_driftBackdropTracked", true);
    QObject::connect(window, &QObject::destroyed, WindowBackdrop::shared(), [window] {
        clearEffect(window);
    });
}

} // namespace

void applyNative(QWindow *window, const QString &backdrop, bool darkVariant)
{
    if (!window)
        return;
    // winId() is a quintptr. A bare cast to NSView* is rejected under ARC;
    // CMake does not pass -fobjc-arc, and the MRC cast is what this target uses.
    void *viewPtr = reinterpret_cast<void *>(window->winId());
#if __has_feature(objc_arc)
    NSView *qtView = (__bridge NSView *)viewPtr;
#else
    NSView *qtView = static_cast<NSView *>(viewPtr);
#endif
    if (!qtView)
        return;
    NSWindow *nsWindow = qtView.window;
    if (!nsWindow)
        return;

    // The Qt view stays on top and draws with an alpha buffer. A clear,
    // non-opaque NSWindow is what lets the effect (or the desktop, when the
    // backdrop is "none") show through pixels the scene graph left transparent.
    nsWindow.opaque = NO;
    nsWindow.backgroundColor = NSColor.clearColor;
    trackWindow(window);

    if (backdrop != QLatin1String("vibrancy") && backdrop != QLatin1String("blur")) {
        clearEffect(window);
        return;
    }

    NSVisualEffectView *effect = effectFromStored(g_effects.value(window, nullptr));
    if (!effect) {
        effect = [[NSVisualEffectView alloc] initWithFrame:qtView.frame];
        effect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        NSView *parent = qtView.superview;
        if (parent)
            [parent addSubview:effect positioned:NSWindowBelow relativeTo:qtView];
        else
            [qtView addSubview:effect positioned:NSWindowBelow relativeTo:nil];
        if (!parent)
            effect.frame = qtView.bounds;
        g_effects.insert(window, retainNewEffect(effect));
    } else if (qtView.superview) {
        effect.frame = qtView.frame;
    }

    effect.material = materialFor(backdrop);
    effect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    effect.state = NSVisualEffectStateActive;
    effect.appearance = [NSAppearance appearanceNamed:(darkVariant ? NSAppearanceNameDarkAqua
                                                                   : NSAppearanceNameAqua)];
}

} // namespace drift::backdrop
