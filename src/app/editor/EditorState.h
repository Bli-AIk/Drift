#pragma once

#include "app/editor/AppController.h"

// Backward-compatible alias used by existing QML.
class EditorState : public AppController
{
    Q_OBJECT

public:
    using AppController::AppController;
};
