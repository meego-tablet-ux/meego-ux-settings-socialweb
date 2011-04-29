VERSION=0.2.5
BASEDIR=/usr/share/meego-ux-settings/
QMLDIR=$$BASEDIR/Socialweb/
TEMPLATE = subdirs
QT += dbus
CONFIG += plugin link_pkgconfig

PKGCONFIG += libsocialweb-qt

OTHER_FILES += qml/*.qml qml/*.js

desktop.files = desktop/*.desktop
desktop.path = $$BASEDIR/apps/

qml.files = qml/*.qml qml/*.js
qml.path = $$QMLDIR

INSTALLS += desktop qml

#********* Translations *********
TRANSLATIONS += $${SOURCES} $${HEADERS} $${OTHER_FILES}
PROJECT_NAME = meego-ux-settings-socialweb

dist.commands += rm -Rf $${PROJECT_NAME}-$${VERSION} &&
dist.commands += git clone . $${PROJECT_NAME}-$${VERSION} &&
dist.commands += rm -Rf $${PROJECT_NAME}-$${VERSION}/.git &&
dist.commands += mkdir -p $${PROJECT_NAME}-$${VERSION}/ts &&
dist.commands += lupdate $${TRANSLATIONS} -ts $${PROJECT_NAME}-$${VERSION}/ts/$${PROJECT_NAME}.ts &&
dist.commands += tar jcpvf $${PROJECT_NAME}-$${VERSION}.tar.bz2 $${PROJECT_NAME}-$${VERSION}
QMAKE_EXTRA_TARGETS += dist
#********* End Translations ******
