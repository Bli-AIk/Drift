#pragma once

#include "models/AppController.h"

// Backward-compatible alias used by existing QML.
class EditorState : public AppController
{
    Q_OBJECT

public:
    using AppController::AppController;
};
