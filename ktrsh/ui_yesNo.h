/********************************************************************************
** Form generated from reading ui file 'yesNo.ui'
**
** Created: Tue Sep 16 16:15:56 2008
**      by: Qt User Interface Compiler version 4.4.1
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
********************************************************************************/

#ifndef UI_YESNO_H
#define UI_YESNO_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QLabel>
#include <QtGui/QPushButton>
#include <QtGui/QWidget>

QT_BEGIN_NAMESPACE

class Ui_yesNoDialog
{
public:
    QLabel *label;
    QPushButton *pushYes;
    QPushButton *pushNo;

    void setupUi(QWidget *yesNoDialog)
    {
    if (yesNoDialog->objectName().isEmpty())
        yesNoDialog->setObjectName(QString::fromUtf8("yesNoDialog"));
    yesNoDialog->resize(399, 117);
    label = new QLabel(yesNoDialog);
    label->setObjectName(QString::fromUtf8("label"));
    label->setGeometry(QRect(20, 10, 361, 41));
    QFont font;
    font.setBold(true);
    font.setWeight(75);
    label->setFont(font);
    pushYes = new QPushButton(yesNoDialog);
    pushYes->setObjectName(QString::fromUtf8("pushYes"));
    pushYes->setGeometry(QRect(40, 70, 105, 27));
    pushNo = new QPushButton(yesNoDialog);
    pushNo->setObjectName(QString::fromUtf8("pushNo"));
    pushNo->setGeometry(QRect(240, 70, 105, 27));

    retranslateUi(yesNoDialog);

    QMetaObject::connectSlotsByName(yesNoDialog);
    } // setupUi

    void retranslateUi(QWidget *yesNoDialog)
    {
    yesNoDialog->setWindowTitle(QApplication::translate("yesNoDialog", "Form", 0, QApplication::UnicodeUTF8));
    label->setText(QApplication::translate("yesNoDialog", "Are you sure you want to delete the selected items?", 0, QApplication::UnicodeUTF8));
    pushYes->setText(QApplication::translate("yesNoDialog", "Yes", 0, QApplication::UnicodeUTF8));
    pushNo->setText(QApplication::translate("yesNoDialog", "No", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(yesNoDialog);
    } // retranslateUi

};

namespace Ui {
    class yesNoDialog: public Ui_yesNoDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_YESNO_H
