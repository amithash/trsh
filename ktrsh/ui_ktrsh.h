/********************************************************************************
** Form generated from reading ui file 'ktrsh.ui'
**
** Created: Sat Sep 13 19:02:57 2008
**      by: Qt User Interface Compiler version 4.4.1
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

#ifndef UI_KTRSH_H
#define UI_KTRSH_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QLabel>
#include <QtGui/QListWidget>
#include <QtGui/QMainWindow>
#include <QtGui/QPushButton>
#include <QtGui/QWidget>

QT_BEGIN_NAMESPACE

class Ui_kTrshWindow
{
public:
    QWidget *centralwidget;
    QListWidget *trshList;
    QPushButton *pushRestore;
    QPushButton *pushRemove;
    QPushButton *pushCancel;
    QLabel *label;
    QPushButton *pushSelectAll;
    QPushButton *pushClear;

    void setupUi(QMainWindow *kTrshWindow)
    {
    if (kTrshWindow->objectName().isEmpty())
        kTrshWindow->setObjectName(QString::fromUtf8("kTrshWindow"));
    kTrshWindow->resize(792, 552);
    centralwidget = new QWidget(kTrshWindow);
    centralwidget->setObjectName(QString::fromUtf8("centralwidget"));
    trshList = new QListWidget(centralwidget);
    trshList->setObjectName(QString::fromUtf8("trshList"));
    trshList->setGeometry(QRect(40, 30, 721, 441));
    trshList->setEditTriggers(QAbstractItemView::SelectedClicked);
    trshList->setSelectionMode(QAbstractItemView::MultiSelection);
    trshList->setResizeMode(QListView::Adjust);
    trshList->setViewMode(QListView::ListMode);
    trshList->setBatchSize(100);
    trshList->setSelectionRectVisible(true);
    trshList->setSortingEnabled(true);
    pushRestore = new QPushButton(centralwidget);
    pushRestore->setObjectName(QString::fromUtf8("pushRestore"));
    pushRestore->setGeometry(QRect(50, 500, 105, 27));
    pushRestore->setCursor(QCursor(Qt::PointingHandCursor));
    pushRemove = new QPushButton(centralwidget);
    pushRemove->setObjectName(QString::fromUtf8("pushRemove"));
    pushRemove->setGeometry(QRect(180, 500, 105, 27));
    pushRemove->setCursor(QCursor(Qt::PointingHandCursor));
    pushCancel = new QPushButton(centralwidget);
    pushCancel->setObjectName(QString::fromUtf8("pushCancel"));
    pushCancel->setGeometry(QRect(650, 500, 105, 27));
    pushCancel->setCursor(QCursor(Qt::PointingHandCursor));
    label = new QLabel(centralwidget);
    label->setObjectName(QString::fromUtf8("label"));
    label->setGeometry(QRect(320, 10, 101, 18));
    pushSelectAll = new QPushButton(centralwidget);
    pushSelectAll->setObjectName(QString::fromUtf8("pushSelectAll"));
    pushSelectAll->setGeometry(QRect(320, 500, 105, 27));
    pushClear = new QPushButton(centralwidget);
    pushClear->setObjectName(QString::fromUtf8("pushClear"));
    pushClear->setGeometry(QRect(440, 500, 105, 27));
    kTrshWindow->setCentralWidget(centralwidget);

    retranslateUi(kTrshWindow);
    QObject::connect(pushCancel, SIGNAL(clicked()), kTrshWindow, SLOT(close()));
    QObject::connect(pushSelectAll, SIGNAL(clicked()), trshList, SLOT(selectAll()));
    QObject::connect(pushClear, SIGNAL(clicked()), trshList, SLOT(clearSelection()));

    QMetaObject::connectSlotsByName(kTrshWindow);
    } // setupUi

    void retranslateUi(QMainWindow *kTrshWindow)
    {
    kTrshWindow->setWindowTitle(QApplication::translate("kTrshWindow", "ktrsh", 0, QApplication::UnicodeUTF8));

#ifndef QT_NO_TOOLTIP
    pushRestore->setToolTip(QApplication::translate("kTrshWindow", "Resore a selected file", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_TOOLTIP

    pushRestore->setText(QApplication::translate("kTrshWindow", "Restore", 0, QApplication::UnicodeUTF8));

#ifndef QT_NO_TOOLTIP
    pushRemove->setToolTip(QApplication::translate("kTrshWindow", "Remove a selected file.", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_TOOLTIP

    pushRemove->setText(QApplication::translate("kTrshWindow", "Remove", 0, QApplication::UnicodeUTF8));

#ifndef QT_NO_TOOLTIP
    pushCancel->setToolTip(QApplication::translate("kTrshWindow", "Cancel and get out", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_TOOLTIP

    pushCancel->setText(QApplication::translate("kTrshWindow", "Close", 0, QApplication::UnicodeUTF8));
    label->setText(QApplication::translate("kTrshWindow", "Trash Contents", 0, QApplication::UnicodeUTF8));
    pushSelectAll->setText(QApplication::translate("kTrshWindow", "Select All", 0, QApplication::UnicodeUTF8));
    pushClear->setText(QApplication::translate("kTrshWindow", "Clear", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(kTrshWindow);
    } // retranslateUi

};

namespace Ui {
    class kTrshWindow: public Ui_kTrshWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_KTRSH_H
