#! /usr/bin/bash
LC_COLLATE=C
shopt -s extglob
PS3='Mostafa_Abdo_DB>>'

function check_name_of_DB {

    if [[ $1 =~ ^[a-zA-Z][a-zA-Z_0-9]*$ ]] ; then
        return 0
    else
        echo 'Error 0x0002 : DataBase can not contain special character '
        return 1
    fi
}


if [[ -d $HOME/.DataBase ]] ; then
    sleep 1
else
    mkdir $HOME/.DataBase
    sleep 2
fi

select choice in Create_DB Connect_DB List_DB Remove_DB 'Exit'
do
    case $REPLY in
        1) 
        #Create_DB
            read -r -p 'Enter Database Name ' DBname
            DBname=$(echo $DBname | tr ' ' '_')
            check_name_of_DB $DBname
            if [[ $? = 0 ]] ; then
                if [[ -d $HOME/.DataBase/$DBname ]] ; then
                    echo 'Error: '$DBname' already exists '
                else
                    mkdir $HOME/.DataBase/$DBname
                    echo 'Create Database Done!'
                    sleep 1
                fi
            fi



        ;;
        2)
        #Connect_DB
            read -r -p 'Enter Database Name ' DBname
            DBname=$(echo $DBname | tr ' ' '_')
            check_name_of_DB $DBname
            if [[ $? = 0 ]] ; then
               if [[ -d $HOME/.DataBase/$DBname ]] ; then
                    cd $HOME/.DataBase/$DBname
                    echo "Enter $DBname DB..."
                    sleep 1
                    source db_table.sh $DBname
                else
                    echo "Database '$DBname' does not exist."

               fi
            fi
        ;;
        3)
        #List_DB
            ls -F $HOME/.DataBase/ | grep / | tr '/' ' '
        ;;
        4)
        #Remove_DB
            DB_list=($(ls -F $HOME/.DataBase/ | grep / | tr '/' ' '))
            folder_count=${#DB_list[@]}
            select choice in $(ls -F $HOME/.DataBase/ | grep / | tr '/' ' ') 'exit'
            do
                case $REPLY in
                    [1-$folder_count])
                        echo "You selected folder: $choice"
                        read -r -p "Are you sure you want to delete '$choice'? (y/n): " confirm
                        if [[ $confirm == [yY] ]]; then
                            rm -r "$HOME/.DataBase/$choice"
                            echo "DataBase '$choice' has been removed."
                        else
                            echo "Operation cancelled."
                        fi
                        break
                    ;;
                     $(($folder_count + 1)))
                     echo "Operation cancelled."
                     break
                    ;;
                    *)
                    echo "Invalid choice. Try again."
                    ;;

                esac
            done
        ;;
        5)
        #exit
            break
        ;;
        *) 
        echo 'Not valid choice try again ....'
        ;;
    esac
done
