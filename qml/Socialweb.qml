/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.Components 0.1
import MeeGo.Settings 0.1
import Socialweb 0.1
import QtWebKit 1.0
import "constants.js" as Const

Labs.ApplicationPage {
    id: container
    title: Const.titleText
    anchors.fill: parent

    SwClient {
        id: swClient
    }

    Translator {
            catalog: "meego-ux-settings-socialweb"
    }

    Component.onCompleted: {
        console.log("Services: " + swClient.getServices());
    }


    Item {
        id: contentArea
        parent: container.content
        anchors.fill: parent

//        property variant compHeights: []

//        function setCompHeight(name, hgt) {
//            var x;
//            console.log("Looking for service " + name + " in CH");
//            for (x in contentArea.compHeights) {
//                //Force it to be a number w/ the multiply
//                var plus1 = (x*1) + 1;
//                //For some reason, can't get the array to just replace the value,
//                //so we splice the values out, then add them back in...
//                if (compHeights[x] == name) {
//                    compHeights = compHeights.splice(x, 2);
//                    break;
//                }
//            }
//            console.log("Appending new service " + name + " to CH, setting: " + hgt);
//            var newSvc = [name, hgt];
//            compHeights = compHeights.concat(newSvc);
//            console.log("new CH: " + compHeights);
//        }

        Image {
            id: sizeImage
            visible: false
            source: Const.iconPath + Const.iconPathGeneric;
            smooth: true
        }

        ListView {
            id: serviceBoxes
            //anchors.fill: parent
            model: swClient.getServices()
            width:  parent.width
            height: parent.height
            //clip: true
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
                    //expandedHeight: 380
                    anchors.left:  parent.left
                    anchors.leftMargin: 2
                    anchors.right:  parent.right
                    anchors.rightMargin: 2
                    //detailsComponent: undefined
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
                            font.pixelSize: theme_fontPixelSizeLarge
                            color: theme_fontColorNormal
                        }

                        Text {
                            id: loggedInName
                            anchors.left: parent.left
                            anchors.top: accountTypeName.bottom
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            text: swServiceConfig.getParamValue(Const.nameParam)
                            elide: Text.ElideRight
                            font.pixelSize: theme_fontPixelSizeNormal
                            color: theme_fontColorNormal
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
//                      onChanged: {
//                          console.log("Expanded changed for " + modelData + ": " + expanded);
//                          var idx;
//                          for (idx in contentArea.compHeights) {
//                              if (contentArea.compHeights[idx] == modelData) {
//                                  //Force it to be a number...
//                                  var idx1 = (idx * 1) + 1;
//                                  console.log("Found it onChanged: setting expHeight to " + contentArea.compHeights[idx1] + " for svc " + modelData);
//                                  expandedHeight = contentArea.compHeights[idx1] + serviceBox.expandButton.height + 20;

//                                  break;
//                              }
//                          }
//                      }
                    Component.onCompleted: {
                        var authType = swServiceConfig.authType;
                        console.log("Auth type: " + authType);
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

                    Item {
                        id: upItem
                        //anchors.fill: parent
//                        color: "#d5d5d5"
                        width: parent.width
                        height: childrenRect.height + 30

                        Component.onCompleted: {
                            credsChanged();
                        }

                        function credsChanged() {
                            var creds = swService.creds;

                            switch (creds) {
                            case SwClientService.CredsUnknown:
                                textStatus.text = Const.signingInText;
                                break;
                            case SwClientService.CredsInvalid:
                                {
                                textStatus.text = Const.cantSignInText;
                                btnApply.text = Const.signInText;
                                }
                                break;
                            case SwClientService.CredsValid:
                                {
                                textStatus.text = Const.signedInText;
                                btnApply.text = Const.signOutText;
                                }
                                break;
                            }
                        }

                        Text {
                            id: textDescription
                            width: parent.width
                            anchors.top: upItem.top
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                            text: swServiceConfig.getDescription() +
                                Const.linkText.arg(swServiceConfig.getLink())
                                .arg(Const.moreDetailsText);
                        }

                        Text {
                            id: textStatus
                            width: parent.width
                            anchors.top: textDescription.bottom
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            visible: swService.configured

                            Component.onCompleted: {
                                credsChanged();
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
                            anchors.top: (textStatus.visible ? textStatus.bottom : textDescription.bottom)
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            anchors.right: parent.right
                            defaultText: Const.usernameDefaultText
                            width: parent.width / 2
                            text: swServiceConfig.getParamValue(Const.nameParam)
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        TextEntry {
                            id: edtPassword
                            anchors.top: edtUName.bottom
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            anchors.right: parent.right
                            defaultText: Const.passwordDefaultText
                            width: parent.width / 2
                            text: swServiceConfig.getParamValue(Const.passwordParam)
                            textInput.echoMode: TextInput.Password
                            visible: (swServiceConfig.authType == SwClientServiceConfig.AuthTypePassword)
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        Button {
                            id: btnApply
                            anchors.top: (edtPassword.visible ? edtPassword.bottom : edtUName.bottom)
                            anchors.topMargin: 12
                            anchors.left: parent.left
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
                    Item {
                        id: flickrItem
                        //anchors.fill: parent
                        width: parent.width
                        height: childrenRect.height + 30

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
                            anchors.top: flickrItem.top
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        Text {
                            id: textStatus
                            width: parent.width
                            anchors.top: textDescription.bottom
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            visible: text
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
                            anchors.top: (textStatus.visible ? textStatus.bottom : textDescription.bottom)
                            anchors.topMargin: 20
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
                                    }
                                } else if (text == Const.continueText) {
                                    if (!swServiceConfig.flickrContinueLogin()) {
                                        textStatus.text = Const.cantSignInText;
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
                    Item {
                        id: facebookItem
                        height: childrenRect.height + 30
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
                            anchors.top: facebookItem.top
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        Text {
                            id: textStatus
                            width: parent.width
                            anchors.top: textDescription.bottom
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            visible: text
                        }

                        Button {
                            id: btnApply
                            property bool inClick: false
                            anchors.top: (textStatus.visible ? textStatus.bottom : textDescription.bottom)
                            anchors.topMargin: 20
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
                    Item {
                        id: oauthItem
                        height: childrenRect.height + 30
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
                            anchors.top: oauthItem.top
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            onLinkActivated: Qt.openUrlExternally(link);
                        }

                        Text {
                            id: textStatus
                            width: parent.width
                            anchors.top: textDescription.bottom
                            anchors.topMargin: 12
                            anchors.left: parent.left
                            color: theme_fontColorNormal
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: theme_fontPixelSizeNormal
                            visible: text
                        }

                        TextEntry {
                            id: edtVerifier
                            anchors.top: textStatus.visible ? textStatus.bottom : textDescription.bottom
                            anchors.left: parent.left
                            anchors.margins: 10
                            defaultText: Const.verifierDefaultText
                            width: parent.width / 2
                            visible: swServiceConfig.oauthNeedsVerifier();
                            textInput.inputMethodHints: Qt.ImhNoAutoUppercase
                        }

                        Button {
                            id: btnApply
                            property bool inClick: false
                            anchors.top: (edtVerifier.visible ? edtVerifier.bottom :
                                          textStatus.visible ? textStatus.bottom : textDescription.bottom)
                            anchors.topMargin: 20
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
                                    }
                                } else if (text == Const.continueText) {
                                    if (edtVerifier.visible) {
                                        swServiceConfig.oauthSetVerifier(edtVerifier.text);
                                    }
                                    if (!swServiceConfig.oauthContinueLogin()) {
                                        textStatus.text = Const.cantSignInText;
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
//            dialogWidth: container.width - 80
//            dialogHeight: container.height - 80
            z: 500

//            onAccepted: {
//                dialogLoader.sourceComponent = undefined;
//            }

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

