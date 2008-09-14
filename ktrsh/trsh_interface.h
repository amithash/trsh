#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string.h>

#define TRSH_LOCATION "/usr/bin/trsh.pl"

using namespace std;

class trshEntry{
	public:
	class trshEntry *next;
	char entry[200];
	int count;
	trshEntry(void)
	{
		entry[0] = '\0';
		count = 0;
		next = NULL;
	}
};

class trshContents{
	public:
	class trshEntry *head;
	trshContents(void)
	{
		;
	}
	~trshContents(void)
	{
		if(head){
			class trshEntry *cur, *nex;
			cur = head;
			nex = head->next;
			while(cur){
				delete cur;
				cur = nex;
				nex = nex->next;
			}
		}
	}

	void add(char *name, int count)
	{
		class trshEntry *iter = head;
		if(!iter){
			head = new trshEntry();
			iter = head;
		} else {
			while(iter->next)
				iter = iter->next;
			iter->next = new trshEntry();
			iter = iter->next;
		}
		strcpy(iter->entry,name);
		if(count > 0)
			iter->count = count;
		else
			iter->count = 0;
	}
	bool is_present(char *name)
	{
		class trshEntry *iter = head;
		while(iter){
			if(strcmp(iter->entry,name) == 0)
				return true;
			iter = iter->next;
		}
		return false;
	}
	bool delete_entry(char *name)
	{
		class trshEntry *iter = head;
		class trshEntry *prev = NULL;
		char cmd[200] = TRSH_LOCATION;
		strcat(cmd," -e ");
		strcat(cmd,name);
		while(iter){
			if(strcmp(iter->entry,name) == 0){
				if(prev)
					prev->next = iter->next;
				if(system(cmd) != 0)
					cout << cmd << " FAILED" << endl;

				delete iter;
				return true;
			}
			prev = iter;
			iter = iter->next;
		}
		return false;
	}

	void populate(void)
	{
		ifstream iff;
		char command[200] = TRSH_LOCATION;
		char entry[255];
		int count = 1;
		strcat(command," -l --no-color --no-count > ktrsh.tmp0001");
		if(system(command) != 0)
			cout << command << " FAILED" << endl;
		iff.open("ktrsh.tmp0001");
		while(1){
			if(iff.eof())
				break;
			iff.getline(entry,255);
			if(strcmp(entry,"") != 0)
				this->add(entry,count);
		}
		iff.close();
		if(system("/bin/rm ktrsh.tmp0001") != 0)
			cout << "removing ktrsh.tmp0001 failed" << endl;
	}
	void print(void)
	{
		trshEntry *iter = head;
		int count = 1;
		while(iter){
			cout << count << " : " << iter->entry << endl;
			count++;
			iter = iter->next;
		}
	}
	void empty(void)
	{
		class trshEntry *iter = head;
		class trshEntry *nex;
		char cmd[200] = TRSH_LOCATION;
		if(iter)
			nex = head->next;

		while(iter){
			delete iter;
			iter = nex;
			nex = nex->next;
		}
		strcat(cmd," -ef");
		if(system(cmd) != 0)
			cout << cmd << " FAILED" << endl;
	}
};


