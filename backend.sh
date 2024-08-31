#!/bin/bash

LOG_FOLDER="var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[33m"
Y="\e[34m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R please run this script in root priveleges $N" | tee -a $LOG_FILE
        exit1
    fi

}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 is... $R failed $N" | tee -a $LOG_FILE
       exit1
    else
       echo -e "$2 is...$R SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"
id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "expense user not exists...$G creating $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "creating expense user"
else
   echo -e "expense user is already created...$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* #remove the existing file
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extract the backend code"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service
 
 dnf install mysql -y &>>$LOG_FILE
 VALIDATE $? "installing mysql"
 
 mysql -h mysql.prudviraj.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
 VALIDATE $? " schema loading"

 systemctl daemon-reload &>>$LOG_FILE
 VALIDATE $? "daemon reload"

 systemctl enable backend &>>$LOG_FILE
 VALIDATE $? "enable backened"

 systemctl restart backend &>>$LOG_FILE
 VALIDATE $? "restart backend"