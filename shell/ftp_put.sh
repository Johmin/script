#!/bin/bash  

time=`date +"%Y%m%d%H%M%S"`
path=/tmp/
file_name=$time.log
ps -ef >$path$file_name

    expect -c "set timeout -1;  
                spawn ftp $1;  
	expect {
		    Name* {send "root"\r;
		    }
		}
    expect {  
            *assword:* {send "111111"\r;  
            }  
        }  
	expect {
		    ftp> {send "put"\r;
		    }
		}
	expect {
		    (local-file) {send "$path$file_name"\r;
		    }
		}
	expect {
		    (remote-file) {send "$file_name"\r;
		    }
		}
	expect {
		    ftp>* {send "bye"\r;
		    }
		}
                "    

