#include <QObject>
#include <QString>
#include <QDir>
#include "ui_ktrsh.h"
#include "ui_restoreDialog.h"
#include "ui_yesNo.h"
#include "trsh_interface.h"

trshContents *t;
QApplication *a;
QMainWindow *wd;
QMainWindow *yesNoWindow;
QMainWindow *restoreWindow;
Ui_kTrshWindow *mw;
Ui_yesNoDialog *yesNoDialog;
Ui_restoreDialog *restoreDialog;
char restoreDir[1000];

class trshInterface : public QObject
{
	Q_OBJECT

	bool removing;
	bool restoring;

	public:
	trshInterface()
	{
		removing = false;
		restoring = false;
	}

	public slots:
	void slotRemove(void)
	{
		if(mw->trshList->count() > 0 && strcmp(mw->trshList->item(0)->text().toStdString().c_str(),"Trash is empty!") != 0){
			if(removing == false && restoring == false){
				removing = true;
				yesNoWindow->show();
			}
		}
	}
	void slotRestore(void)
	{
		if(mw->trshList->count() > 0 && strcmp(mw->trshList->item(0)->text().toStdString().c_str(),"Trash is empty!") != 0){
			ifstream iff;
			if(restoring == false && removing == false){
				restoring = true;
				QDir *dir = new QDir();
				QString curDir = dir->canonicalPath();
				delete dir;
				restoreDialog->restoreText->insertPlainText(curDir);
				restoreWindow->show();
			}
		}
	}
	void slotRemoveYes(void)
	{
		if(removing == true){
			Remove();
			removing = false;
			yesNoWindow->hide();
		}
	}
	
	void slotRemoveNo(void)
	{
		if(removing == true){
			removing = false;
			yesNoWindow->hide();
		}
	}

	void slotRestoreOk(void)
	{
		if(restoring == true){
			restoring = false;
			restoreWindow->hide();
			strcpy(restoreDir,restoreDialog->restoreText->toPlainText().toStdString().c_str());
			Restore();
		}
	}

	void slotRestoreCancel(void)
	{
		if(restoring == true){
			restoring = false;
			restoreWindow->hide();
		}
	}

	public:
	void Remove(void)
	{
		char itemName[255];
		QListWidgetItem *item;
		for(int i=0;i<mw->trshList->count();i++){
			if(mw->trshList->item(i)->isSelected()){
				char cmd[500] = TRSH_LOCATION;
				item = mw->trshList->takeItem(i);
				strcpy(itemName,item->text().toStdString().c_str());
				strcat(cmd, " -ef ");
				strcat(cmd, itemName);
				if(system(cmd) != 0)
					cout << "ktrsh: Could not remove " << itemName << endl;
				i--;
			}
		}
	}

	void Restore(void)
	{
		char itemName[255];
		QListWidgetItem *item;
		QDir::setCurrent(restoreDir);
		
		for(int i=0;i<mw->trshList->count();i++){
			if(mw->trshList->item(i)->isSelected()){
				char cmd[500] = TRSH_LOCATION;
				item = mw->trshList->takeItem(i);
				strcpy(itemName,item->text().toStdString().c_str());
				strcat(cmd, " -u ");
				strcat(cmd, itemName);
				if(system(cmd) != 0)
					cout << "ktrsh: Could not recover " << itemName << endl;
				i--;
			}
		}
	} 
};

#include "main.moc"


int main(int argc, char *argv[])
{
    trshEntry *iter;
    t = new trshContents();
    t->populate();
    a = new QApplication(argc,argv);
    wd = new QMainWindow();
    yesNoWindow = new QMainWindow();
    restoreWindow = new QMainWindow();
    mw = new Ui_kTrshWindow();
    restoreDialog = new Ui_restoreDialog();
    yesNoDialog = new Ui_yesNoDialog();
    trshInterface *inter = new trshInterface();

    mw->setupUi(wd);
    restoreDialog->setupUi(restoreWindow);
    yesNoDialog->setupUi(yesNoWindow);

    a->connect( a, SIGNAL( lastWindowClosed() ), a, SLOT( quit() ) );
    a->connect(mw->pushRestore, SIGNAL(clicked()), inter, SLOT(slotRestore()));
    a->connect(mw->pushRemove, SIGNAL(clicked()), inter, SLOT(slotRemove()));
    a->connect(yesNoDialog->pushYes, SIGNAL(clicked()), inter, SLOT(slotRemoveYes()));
    a->connect(yesNoDialog->pushNo, SIGNAL(clicked()), inter, SLOT(slotRemoveNo()));
    a->connect(restoreDialog->pushRestoreOk,SIGNAL(clicked()),inter,SLOT(slotRestoreOk()));
    a->connect(restoreDialog->pushRestoreCancel,SIGNAL(clicked()),inter,SLOT(slotRestoreCancel()));

    QMetaObject::connectSlotsByName(a);
   
    iter = t->head;
    while(iter){
    	mw->trshList->addItem(iter->entry);
	iter = iter->next;
    }
    wd->show();
    int result = a->exec();
    delete mw;
    delete wd;
    delete restoreDialog;
    delete restoreWindow;
    delete yesNoDialog;
    delete yesNoWindow;
//    delete t;
    return result;
}

