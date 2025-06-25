#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "fileStream.h"
#include "fileInfo.h"
#include "filelead.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    qmlRegisterType<FileStream>("com.player", 1, 0, "FileStream");
    qmlRegisterType<FileInfo>("imageTools", 1, 0, "ImageInfo");
    qmlRegisterType<FileLead>("FileTree", 1, 0, "FileLead");
    FileStream fileStream;
    FileInfo fileInfo;
    FileLead fileLead;
    engine.rootContext()->setContextProperty("fileStream", &fileStream);
    engine.rootContext()->setContextProperty("fileInfo", &fileInfo);
    engine.rootContext()->setContextProperty("fileLead", &fileLead);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("player", "Window");

    return app.exec();
}
