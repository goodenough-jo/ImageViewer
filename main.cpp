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

    FileStream *fileStream = new FileStream(&app);
    FileInfo *fileInfo = new FileInfo(&app);
    FileLead *fileLead = new FileLead(&app);

    qmlRegisterType<FileLead>("FileTree", 1, 0, "FileLead");

    engine.rootContext()->setContextProperty("fileStream", fileStream);
    engine.rootContext()->setContextProperty("fileInfo", fileInfo);
    engine.rootContext()->setContextProperty("fileLead", fileLead);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("player", "Window");

    return app.exec();
}
