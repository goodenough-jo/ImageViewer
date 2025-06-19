#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "fileStream.h"
#include "fileInfo.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    qmlRegisterType<FileStream>("com.player", 1, 0, "FileStream");
    qmlRegisterType<FileInfo>("imageTools", 1, 0, "ImageInfo");
    FileStream fileStream;
    FileInfo fileInfo;
    engine.rootContext()->setContextProperty("fileStream", &fileStream);
    engine.rootContext()->setContextProperty("fileInfo", &fileInfo);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("player", "Window");

    return app.exec();
}
