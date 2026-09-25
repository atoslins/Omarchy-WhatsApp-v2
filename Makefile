.PHONY: validate test manifest lint release-check dev demo

OMARCHY_SHELL_DIR ?= /usr/share/omarchy/shell
# Arch installs the Qt tools outside PATH.
export PATH := $(PATH):/usr/lib/qt6/bin

validate: test manifest lint

test:
	python3 -m py_compile bin/omawhatsapp bin/omawhatsapp_core.py bin/omawhatsapp_assets.py bin/omawhatsapp-mcp
	OMAW_SCRIPT="$(CURDIR)/bin/omawhatsapp_core.py" python3 -B -m unittest discover -s tests -v
	jq empty manifest.json plugins/omawhatsapp/manifest.json

manifest:
	omarchy plugin validate .

lint:
	qmllint -I "$(OMARCHY_SHELL_DIR)" plugins/omawhatsapp/UpdateController.qml plugins/omawhatsapp/MaintenanceSettings.qml
	qmllint -I "$(OMARCHY_SHELL_DIR)" plugins/omawhatsapp/TimeFormat.js plugins/omawhatsapp/ComposerModel.js plugins/omawhatsapp/MediaModel.js plugins/omawhatsapp/MediaViewerLogic.js plugins/omawhatsapp/DropdownModel.js plugins/omawhatsapp/SettingsPolicy.js plugins/omawhatsapp/AccountModel.js plugins/omawhatsapp/VoiceRecorderModel.js plugins/omawhatsapp/KeyboardNavigation.qml plugins/omawhatsapp/AccountReadiness.qml plugins/omawhatsapp/AccountOperations.qml plugins/omawhatsapp/AccountSwitcher.qml plugins/omawhatsapp/ChatAvatar.qml plugins/omawhatsapp/AcknowledgementQueue.qml plugins/omawhatsapp/PlaybackCoordinator.qml plugins/omawhatsapp/VoiceRecorder.qml plugins/omawhatsapp/VoiceComposer.qml plugins/omawhatsapp/VideoPlayer.qml plugins/omawhatsapp/App.qml plugins/omawhatsapp/Service.qml plugins/omawhatsapp/MessageBubble.qml plugins/omawhatsapp/MediaBubble.qml plugins/omawhatsapp/MediaViewer.qml plugins/omawhatsapp/MediaViewerModel.qml plugins/omawhatsapp/BarWidget.qml plugins/omawhatsapp/Dropdown.qml plugins/omawhatsapp/SettingsView.qml plugins/omawhatsapp/EmojiPicker.qml plugins/omawhatsapp/EmojiModel.js plugins/omawhatsapp/LinkModel.js plugins/omawhatsapp/NewChatDialog.qml plugins/omawhatsapp/ChatDetailsPanel.qml plugins/omawhatsapp/QuickSwitcher.qml plugins/omawhatsapp/MediaBrowser.qml plugins/omawhatsapp/GroupAdmin.qml plugins/omawhatsapp/FormatModel.js plugins/omawhatsapp/PresenceModel.js plugins/omawhatsapp/FormatMenu.qml plugins/omawhatsapp/FormatBar.qml plugins/omawhatsapp/RoundedCorners.qml plugins/omawhatsapp/GroupDialog.qml

release-check:
	./scripts/test

# Copy working-tree changes over an existing standalone install.
dev:
	./scripts/dev-sync

# Open the full app with repository-owned demo data (safe for screenshots).
demo:
	omarchy-shell io.github.moizibnyousaf.omawhatsapp openApp '{"demo":true}'
