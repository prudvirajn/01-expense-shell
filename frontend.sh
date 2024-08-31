#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log
mkdir -p $LOGS_FOLDER

USERID=(id -u)
R="\e[31m"
G="\e[32m"
N="\e[33m"
Y="\e[34m"


CHECK_ROOT(){
    if [ $sUSERID -ne 0 ]
    then
       echo -e "$R run this script with root priveleges $N" | tee -a $LOG_FILE
       exit1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ...$R FAILED $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is...$G success $N" | tee -a $LOG_FILE
    fi
}   

echo "script started executed at $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enable nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "removing default website"


curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloding frontend code"

cd usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "extracting the application code"


cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"
