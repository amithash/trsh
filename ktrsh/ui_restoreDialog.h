/********************************************************************************
** Form generated from reading ui file 'restoreDialog.ui'
**
** Created: Sat Sep 13 19:02:57 2008
**      by: Qt User Interface Compiler version 4.4.1
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

#ifndef UI_RESTOREDIALOG_H
#define UI_RESTOREDIALOG_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QPushButton>
#include <QtGui/QTextEdit>
#include <QtGui/QWidget>

QT_BEGIN_NAMESPACE

class Ui_restoreDialog
{
public:
    QTextEdit *restoreText;
    QPushButton *pushRestoreOk;
    QPushButton *pushRestoreCancel;

    void setupUi(QWidget *restoreDialog)
    {
    if (restoreDialog->objectName().isEmpty())
        restoreDialog->setObjectName(QString::fromUtf8("restoreDialog"));
    restoreDialog->resize(456, 145);
    restoreText = new QTextEdit(restoreDialog);
    restoreText->setObjectName(QString::fromUtf8("restoreText"));
    restoreText->setGeometry(QRect(20, 10, 401, 41));
    pushRestoreOk = new QPushButton(restoreDialog);
    pushRestoreOk->setObjectName(QString::fromUtf8("pushRestoreOk"));
    pushRestoreOk->setGeometry(QRect(50, 90, 105, 27));
    pushRestoreCancel = new QPushButton(restoreDialog);
    pushRestoreCancel->setObjectName(QString::fromUtf8("pushRestoreCancel"));
    pushRestoreCancel->setGeometry(QRect(240, 90, 105, 27));

    retranslateUi(restoreDialog);

    QMetaObject::connectSlotsByName(restoreDialog);
    } // setupUi

    void retranslateUi(QWidget *restoreDialog)
    {
    restoreDialog->setWindowTitle(QApplication::translate("restoreDialog", "Form", 0, QApplication::UnicodeUTF8));
    pushRestoreOk->setText(QApplication::translate("restoreDialog", "Ok", 0, QApplication::UnicodeUTF8));
    pushRestoreCancel->setText(QApplication::translate("restoreDialog", "Cancel", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(restoreDialog);
    } // retranslateUi

};

namespace Ui {
    class restoreDialog: public Ui_restoreDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_RESTOREDIALOG_H
