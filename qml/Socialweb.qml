/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Settings 0.1
import Socialweb 0.1
import QtWebKit 1.0
import "constants.js" as Const

AppPage {
    id: container
    pageTitle: Const.titleText
    anchors.fill: parent

    SwClient {
        id: swClient
    }

    Translator {
            catalog: "meego-ux-settings-socialweb"
    }

    Theme {
        id: theme
    }

    Component.onCompleted: {
        console.debug("Services: " + swClient.getServices());
    }


    Item {
        id: contentArea
        anchors.fill: parent

        Image {
            id: sizeImage
            visible: false
            source: Const.iconPath + Const.iconPathGeneric;
            smooth: true
        }

        ListView {
            id: serviceBoxes
            model: swClient.getServices()
            width:  parent.width
            height: parent.height
            interactive: (height < contentHeight)
            spacing: 2

            delegate: Item {
                id: delServices
                width: parent.width
                height: serviceBox.height

                SwClientService {
                    id: swService
                    serviceName: modelData
                }

                SwClientServiceConfig {
                    id: swServiceConfig
                    service: swService
                }

                ExpandingBox {
                    id: serviceBox
                    expanded: false
                    anchors.left:  parent.left
                    anchors.leftMargin: 2
                    anchors.right:  parent.right
                    anchors.rightMargin: 2
                    height: sizeImage.height // TODO: once ExpandingBox is working properly, go this way
                    //height: (sizeImage.height ? sizeImage.height : 75)
                    property bool first: true
                    onHeightChanged: {
                        if (first) {
                            buttonHeight = height;
                            first = false;
                        }
                    }

                    Image {
                        id: serviceIcon
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        asynchronous: true
                        width: sizeImage.width
                        height: sizeImage.height
                        source: (swService.configured && swService.hasRequestAvatar() ?
                                 swService.getUserAvatarPath() :
                                 Const.iconPath + swService.getServiceName())
                        smooth: true

                        onStatusChanged: {
                            if (status == Image.Error || status == Image.Null) {
                                // Use fallback image
                                serviceIcon.source = Const.iconPath + Const.iconPathGeneric;
                            }
                        }
                    }

                    Rectangle {
                        id: serviceRect
                        anchors.left: serviceIcon.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: serviceIcon.verticalCenter
                        height: accountTypeName.height

                        states: State {
                            name: "multiline"

                            PropertyChanges {
                                target: serviceRect
                                height: accountTypeName.height + loggedInName.height + 10
                            }
                            when: { loggedInName.visible }
                        }
                        transitions: Transition {
                            SequentialAnimation {
                                NumberAnimation {
                                    properties: "height"
                                    duration: 200
                                    easing.type: Easing.InCubic
                                }
                            }
                        }

                        Text {
                            id: accountTypeName
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            text: swService.getDisplayName()
                            elide: Text.ElideRight
                            font.pixelSize: theme.fontPixelSizeLarge
                            color: theme.fontColorNormal
                        }

                        Text {
                            id: loggedInName
                            anchors.left: parent.left
                            anchors.top: accountTypeName.bottom
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            text: swServiceConfig.getParamValue(Const.nameParam)
                            elide: Text.ElideRight
                            font.pixelSize: theme.fontPixelSizeNormal
                            color: theme.fontColorNormal
                            visible: (swService.creds == SwClientService.CredsValid &&
                                      serviceBox.expanded == false)
                        }
                    }

                    Connections {
                        target: swService
                        onCredsChanged: {
                            switch (swService.creds) {
                            case SwClientService.CredsUnknown:
                            case SwClientService.CredsInvalid: {
                                loggedInName.text = "";
                                serviceIcon.source = Const.iconPath + swService.getServiceName();
                                }
                                break;
                            case SwClientService.CredsValid: {
                                loggedInName.text = swServiceConfig.getParamValue(Const.nameParam);
                                swService.requestAvatar();
                                }
                                break;
                            }
                        }

                        onCanRequestAvatarChanged: {
                            swService.requestAvatar();
                        }

                        onAvatarRetrieved: {
                            serviceIcon.source = swService.getUserAvatarPath();
                        }
                    }

                    Connections {
                        target: swServiceConfig
                        onUsernameChanged: {
                            loggedInName.text = swServiceConfig.getParamValue(Const.nameParam);
                        }
                    }
                    Component.onCompleted: {
                        var authType = swServiceConfig.authType;
                        console.debug("Auth type: " + authType);
                        switch (authType) {
                        case SwClientServiceConfig.AuthTypeUsername:
                        case SwClientServiceConfig.AuthTypePassword:
                            serviceBox.detailsComponent = upService;
                            break;
                        case SwClientServiceConfig.AuthTypeFlickr:
                            serviceBox.detailsComponent = flickrService;
                            break;
                        case SwClientServiceConfig.AuthTypeFacebook:
                            serviceBox.detailsComponent = facebookService;
                            break;
                        case SwClientServiceConfig.AuthTypeOAuth:
                            serviceBox.detailsComponent = oauthService;
                            break;
                        case SwClientServiceConfig.AuthTypeCustom:
                            //TODO - figure out how to handle custom auth types
                            console.log("Custom auth type - unhandled! Type: "
                                        + swServiceConfig.getCustomAuthtype());
                            break;
                        case SwClientServiceConfig.AuthTypeUnknown:
                            console.log("Unknown auth type! Type: "
                                        + swServiceConfig.getCustomAuthtype());
                            break;
                        }
                    }
                }

                Component {
                    id: upService

                    Column {
                        id: upItem
                        width: parent.width
                        spacing: 12

                        Component.onCompleted: {
                            credsChanged();
                        }

                        function credsChanged() {
                            var creds = swService.creds;

                            switch (creds) {
                            case SwClientService.CredsUnknown:
                                textStatus.text = Const.signingInText;
                                textStatus.show();
                                break;
                            case SwClientService.CredsInvalid:
                                {
                                textStatus.text = Const.cantSignInText;
                                textStatus.show();
                                btnApply.text = Const.signInText;
                                }
                                break;
                            case SwClientService.CredsValid:
                                {
                                textStatus.text = Const.signedInText;
                                textStatus.show();
                                btnApply.text = Const.signOutText;
                                }
                                break;
                            }
                        }

                        Text {
                            id: textDescription
                            width: parent.width
                            color: theme.fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme.fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                            text: swServiceConfig.getDescription() +
                                Const.linkText.arg(swServiceConfig.getLink())
                                .arg(Const.moreDetailsText);
                        }

                        InfoBar {
                            id: textStatus
                            width: parent.width
                            visible: swService.configured

                            Component.onCompleted: {
                                credsChanged();
                            }

                        }

                        InfoBar {
                            id: sharingService
                            width: parent.width
                            text: Const.sharingOnlyText;

                            Component.onCompleted: {
                                if (!swService.hasOpenView())
                                    sharingService.show();
                            }
                        }

                        Connections {
                            target: swService
                            onConfiguredChanged: {
                                textStatus.visible = swService.configured;
                            }
                            onCredsChanged: {
                                credsChanged();
                            }
                        }

                        TextEntry {
                            id: edtUName
                            defaultText: Const.usernameDefaultText
                            width: parent.width
                            text: swServiceConfig.getParamValue(Const.nameParam)
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        TextEntry {
                            id: edtPassword
                            defaultText: Const.passwordDefaultText
                            width: parent.width
                            text: swServiceConfig.getParamValue(Const.passwordParam)
                            textInput.echoMode: TextInput.Password
                            visible: (swServiceConfig.authType == SwClientServiceConfig.AuthTypePassword)
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        Button {
                            id: btnApply
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Const.buttonHeight
                            width: Const.buttonWidth
                            text: Const.signInText

                            onClicked: {
                                if (text == Const.signInText) {
                                    btnApply.text = Const.signOutText;
                                    swServiceConfig.setParamValue(Const.nameParam, edtUName.text);
                                    swServiceConfig.setParamValue(Const.passwordParam, edtPassword.text);
                                    swServiceConfig.saveConfigParams();
                                } else {
                                    btnApply.text = Const.signInText;
                                    edtUName.text = "";
                                    swServiceConfig.setParamValue(Const.nameParam, "");
                                    edtPassword.text = "";
                                    swServiceConfig.setParamValue(Const.passwordParam, "");
                                    swServiceConfig.saveConfigParams();
                                }
                            }
                        }
                    }
                }

                Component {
                    id: flickrService
                    Column {
                        id: flickrItem
                        width: parent.width
                        spacing: 12

                        Component.onCompleted: {
                            credsChanged();
                        }

                        function credsChanged() {
                            var creds = swService.creds;

                            switch (creds) {
                                case SwClientService.CredsValid: {
                                    btnApply.text = Const.signOutText
                                    textDescription.text = Const.usernameText +
                                        swServiceConfig.getParamValue(Const.nameParam);
                                    }
                                    break;
                                case SwClientService.CredsInvalid: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                                case SwClientService.CredsUnknown: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                            }
                        }

                        Connections {
                            target: swServiceConfig
                            onUsernameChanged: credsChanged()
                        }

                        Text {
                            id: textDescription
                            width: parent.width
                            color: theme.fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme.fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        InfoBar {
                            id: textStatus
                            width: parent.width
                        }

                        InfoBar {
                            id: sharingService
                            width: parent.width
                            text: Const.sharingOnlyText;

                            Component.onCompleted: {
                                if (!swService.hasOpenView())
                                    sharingService.show();
                            }
                        }

                        Connections {
                            target: swService
                            onCredsChanged: {
                                credsChanged();
                            }
                        }

                        Button {
                            id: btnApply
                            property bool inClick: false
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Const.buttonHeight
                            width: Const.buttonWidth
                            text: Const.signInText

                            onClicked: {
                                spinner.visible = true;
                                spinner.spinning = true;

                                // Prevent multiple clicks
                                if (!inClick) {
                                    inClick = true;
                                } else {
                                    return;
                                }

                                if (text == Const.signInText) {
                                    var loginUrl = swServiceConfig.flickrOpenLoginUrl();
                                    if (loginUrl) {
                                        webAuthDialog.show();
                                        webAuthDialog.url = loginUrl;
                                        btnApply.text = Const.continueText
                                    } else {
                                        textStatus.text = Const.cantSignInText;
                                        textStatus.show();
                                    }
                                } else if (text == Const.continueText) {
                                    if (!swServiceConfig.flickrContinueLogin()) {
                                        textStatus.text = Const.cantSignInText;
                                        textStatus.show();
                                        btnApply.text = Const.signInText;
                                    }
                                    else {
                                        textStatus.text = "";
                                    }
                                } else {
                                    swServiceConfig.flickrDeleteLogin();
                                }

                                inClick = false;
                                spinner.visible = false;
                                spinner.spinning = false;
                            }

                            Spinner {
                                id: spinner
                                z: 100

                                visible: false
                                spinning: false

                                onSpinningChanged: {
                                    if (!spinning)
                                        spinning = true
                                }
                            }

                        }
                    }
                }

                Component {
                    id: facebookService
                    Column {
                        id: facebookItem
                        spacing: 12
                        width: parent.width

                        Component.onCompleted: {
                            credsChanged()
                        }

                        function credsChanged() {
                            var creds = swService.creds;

                            switch (creds) {
                                case SwClientService.CredsValid: {
                                    btnApply.text = Const.signOutText
                                    textDescription.text = Const.usernameText +
                                        swServiceConfig.getParamValue(Const.nameParam);
                                    }
                                    break;
                                case SwClientService.CredsInvalid: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                                case SwClientService.CredsUnknown: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                            }
                        }

                        Connections {
                            target: swServiceConfig
                            onUsernameChanged: credsChanged()
                        }

                        Text {
                            id: textDescription
                            width: parent.width
                            color: theme.fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme.fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        InfoBar {
                            id: textStatus
                            width: parent.width
                        }

                        InfoBar {
                            id: sharingService
                            width: parent.width
                            text: Const.sharingOnlyText;

                            Component.onCompleted: {
                                if (!swService.hasOpenView())
                                    sharingService.show();
                            }
                        }

                        Button {
                            id: btnApply
                            property bool inClick: false
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Const.buttonHeight
                            width: Const.buttonWidth
                            text: Const.signInText
                            onClicked: {
                                spinner.visible = true;
                                spinner.spinning = true;

                                // Prevent multiple clicks
                                if (!inClick) {
                                    inClick = true;
                                } else {
                                    return;
                                }

                                if (text == Const.signInText) {
                                    var loginUrl = swServiceConfig.facebookOpenLogin();
                                    if (loginUrl) {
                                        webAuthDialog.show()
                                        webAuthDialog.url = loginUrl;
                                        webAuthDialog.testurl = "http://www.facebook.com/connect/login_success.html";
                                    } else {
                                        textStatus.text = Const.cantSignInText;
                                        textStatus.show();
                                    }
                                } else {
                                    swServiceConfig.facebookDeleteLogin();
                                    textDescription.text = Const.signedOutText;
                                }

                                inClick = false;
                                spinner.visible = false;
                                spinner.spinning = false;
                            }

                            Connections {
                                ignoreUnknownSignals: true
                                target: webAuthDialog
                                onLoggedIn: {
                                    spinner.visible = true;
                                    spinner.spinning = true;
                                    swServiceConfig.facebookLoggedIn(url);
                                    spinner.visible = false;
                                    spinner.spinning = false;
                                }
                            }

                            Spinner {
                                id: spinner
                                z: 100

                                visible: false
                                spinning: false

                                onSpinningChanged: {
                                    if (!spinning)
                                        spinning = true
                                }
                            }

                        }

                        Connections {
                            target: swService

                            onCredsChanged: {
                                credsChanged();
                            }
                        }

                    }
                }

                Component {
                    id: oauthService
                    Column {
                        id: oauthItem
                        spacing: 12
                        width: parent.width

                        Component.onCompleted: {
                            credsChanged()
                        }

                        function credsChanged() {
                            var creds = swService.creds;

                            switch (creds) {
                                case SwClientService.CredsValid: {
                                    btnApply.text = Const.signOutText
                                    textDescription.text = Const.usernameText +
                                        swServiceConfig.getParamValue(Const.nameParam);
                                    }
                                    break;
                                case SwClientService.CredsInvalid: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                                case SwClientService.CredsUnknown: {
                                    btnApply.text = Const.signInText
                                    textDescription.text = swServiceConfig.getDescription() +
                                        Const.linkText.arg(swServiceConfig.getLink())
                                        .arg(Const.moreDetailsText);
                                    }
                                    break;
                            }
                        }

                        Connections {
                            target: swServiceConfig
                            onUsernameChanged: credsChanged()
                        }

                        Text {
                            id: textDescription
                            width: parent.width
                            color: theme.fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme.fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        InfoBar {
                            id: textStatus
                            width: parent.width
                        }

                        InfoBar {
                            id: sharingService
                            width: parent.width
                            text: Const.sharingOnlyText;

                            Component.onCompleted: {
                                if (!swService.hasOpenView())
                                    sharingService.show();
                            }
                        }

                        TextEntry {
                            id: edtVerifier
                            defaultText: Const.verifierDefaultText
                            width: parent.width
                            visible: swServiceConfig.oauthNeedsVerifier();
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        Button {
                            id: btnApply
                            property bool inClick: false
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Const.buttonHeight
                            width: Const.buttonWidth
                            text: Const.signInText
                            onClicked: {
                                spinner.visible = true;
                                spinner.spinning = true;

                                // Prevent multiple clicks
                                if (!inClick) {
                                    inClick = true;
                                } else {
                                    return;
                                }

                                if (text == Const.signInText) {
                                    var loginUrl = swServiceConfig.oauthOpenLogin();
                                    if (loginUrl) {
                                        webAuthDialog.show()
                                        webAuthDialog.url = loginUrl;
                                        console.log("opening auth site " + loginUrl);
                                        btnApply.text = Const.continueText;
                                        edtVerifier.visible = swServiceConfig.oauthNeedsVerifier();
                                    }
                                    else {
                                        textStatus.text = Const.cantSignInText;
                                        textStatus.show();
                                    }
                                } else if (text == Const.continueText) {
                                    if (edtVerifier.visible) {
                                        swServiceConfig.oauthSetVerifier(edtVerifier.text);
                                    }
                                    if (!swServiceConfig.oauthContinueLogin()) {
                                        textStatus.text = Const.cantSignInText;
                                        textStatus.show();
                                        btnApply.text = Const.signInText;
                                    }
                                    else {
                                        textStatus.text = "";
                                    }
                                } else {
                                    swServiceConfig.oauthDeleteLogin();
                                    textDescription.text = Const.signedOutText;
                                }

                                inClick = false;
                                spinner.visible = false;
                                spinner.spinning = false;
                            }

                            Spinner {
                                id: spinner
                                z: 100

                                visible: false
                                spinning: false

                                onSpinningChanged: {
                                    if (!spinning)
                                        spinning = true
                                }
                            }

                        }

                        Connections {
                            target: swService

                            onCredsChanged: {
                                credsChanged();
                            }
                        }
                    }
                }


            }
        }

        ModalDialog {
            id: webAuthDialog
            property string url
            property string testurl
            signal loggedIn(string url)

            acceptButtonText: Const.dialogButtonText
            showAcceptButton: true
            showCancelButton: false
            title: Const.dialogTitleText
            width: container.width - 80
            height: container.height - 80
            z: 500

            content: Flickable {
                id: flickable
                anchors.left: parent.left
                //anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                //anchors.bottom: parent.bottom
                width: webAuthDialog.width - 20
                height: webAuthDialog.height - 20
                contentWidth: Math.max(width, webAuthWebView.width)
                contentHeight: Math.max(height, webAuthWebView.height)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WebView {
                    id: webAuthWebView
                    url: webAuthDialog.url
                    //anchors.fill: parent
                    preferredWidth: parent.width
                    preferredHeight: parent.height

                    onLoadFinished: {
                        spinner.visible = false;
                        spinner.spinning = false;
                        if (webAuthDialog.testurl &&
                            url.toString().indexOf(webAuthDialog.testurl) == 0) {
                            webAuthDialog.hide();// = false;
                            webAuthDialog.loggedIn(url.toString());
                        }
                    }

                    onLoadStarted: {
                        spinner.visible = true;
                        spinner.spinning = true;
                    }

                    Spinner {
                        id: spinner
                        z: 600

                        visible: false
                        spinning: false

                        onSpinningChanged: {
                            if (!spinning)
                                spinning = true
                        }
                    }

                }
            }
        } //ModalDialog
    }

}

