#! /usr/bin/bash
LC_COLLATE=C
shopt -s extglob


function check_name_of_DB {

    if [[ $1 =~ ^[a-zA-Z][a-zA-Z_0-9]*$ ]] ; then
        return 0
    else
        echo 'Error 0x0002 : DataBase can not contain special character '
        return 1
    fi
}

select choice in Create_Table Drop_Table Insert_Table Select Delete_Table Update_Table List_Table 'Exit'
do

    case $REPLY in

    1)
#create table
read -r -p 'Enter Table Name ' TBname
TBname=$(echo $TBname | tr ' ' '_')
check_name_of_DB $TBname
if [[ $? = 0 ]] ; then
    if [[ -f $HOME/.DataBase/$DBname/$TBname ]] ; then
        echo 'Error: Table already exists '
        break
    else
        touch "$HOME/.DataBase/$DBname/.${TBname}_meta"
        touch "$HOME/.DataBase/$DBname/${TBname}"
    fi
    while true ; do
        read -r -p 'Enter the number of fields: ' num_fields
        if [[ $num_fields =~ ^[0-9]+$ ]] ; then
            echo "Fields: $num_fields"
            break
        else
            echo 'Number of fields must be an integer'
        fi
    done
    echo "The first field MUST be the PK and must be of type int."
    for ((i=1 ; i<=$num_fields ; i++)); do
        while true; do
            read -r -p "Enter field Name for field $i: " fieldName
            fieldName=$(echo $fieldName | tr ' ' '_')
            check_name_of_DB $fieldName
            if [[ $? = 0 ]] ; then
                break
            else
                echo "Invalid field name. It must not start with a number or special character."
            fi
        done

        if [[ $i -eq 1 ]]; then
            
            
            while true; do
                read -r -p "Is this field a primary key? (yes/no): " is_pk
                if [[ "$is_pk" =~ ^(yes|Yes|YES|YEs)$ ]]; then
                    pk_status="PK"
                    break
                elif [[ "$is_pk" =~ ^(no|No|NO)$ ]]; then
                    echo "Error: The first field must be the PK."
                    continue  
                    
                else
                    echo 'Please enter Yes or No'
                fi
            done


            while true; do
                read -r -p "Enter data type for field $i (string/int): " data_type
                if [[ $data_type =~ ^(int|INT|Int)$ ]]; then
                    type_status='int'
                    break
                else
                    echo "The first field must be of type int."
                fi
            done
        else

            while true; do
                read -r -p "Is this field a primary key? (yes/no): " is_pk
                if [[ "$is_pk" =~ ^(yes|Yes|YES|YEs)$ ]]; then
                    pk_status="PK"
                    break
                elif [[ "$is_pk" =~ ^(no|No|NO)$ ]]; then
                    pk_status="Not PK"
                    break
                else
                    echo 'Please enter Yes or No'
                fi
            done

            while true; do
                read -r -p "Enter data type for field $i (string/int): " data_type
                if [[ $data_type =~ ^(STRING|str|STR|string)$ ]]; then
                    type_status='string'
                    break
                elif [[ $data_type =~ ^(int|INT|Int)$ ]]; then
                    type_status='int'
                    break
                else
                    echo "Invalid data type. Only 'string' or 'int' are allowed."
                fi
            done
        fi

        echo "$fieldName:$pk_status:$type_status" >> "$HOME/.DataBase/$DBname/.${TBname}_meta"

    done

    echo "Table $TBname created successfully!"
fi
source db_table.sh
    ;;
    2)
    #drop table
            TB_list=($(ls $HOME/.DataBase/$DBname))
            Table_count=${#TB_list[@]}
            select choice in $(ls $HOME/.DataBase/$DBname) 'exit'
            do
                case $REPLY in
                    [1-$Table_count])

                        echo "You selected Table: $choice"
                        read -r -p "Are you sure you want to delete '$choice'? (y/n): " confirm
                        if [[ $confirm == [yY] ]]; then
                            rm -f "$HOME/.DataBase/$DBname/$choice" "$HOME/.DataBase/$DBname/.${choice}_meta"
                            echo "Table '$choice' has been removed."
                        else
                            echo "Operation cancelled."
                        fi
                        break
                    ;;
                     $(($Table_count + 1)))
                     echo "Operation cancelled."
                     source db_table.sh
                    ;;
                    *)
                    echo "Invalid choice. Try again."
                    ;;

                esac
            done
    
    ;;
    3)
    #insert table
TB_list=($(ls $HOME/.DataBase/$DBname))
Table_count=${#TB_list[@]}

select choice in "${TB_list[@]}" "Exit"; do
    case $REPLY in
        [1-$Table_count])
            data_file="$HOME/.DataBase/$DBname/$choice"
            meta_file="$HOME/.DataBase/$DBname/.${choice}_meta"

            columns=($(awk -F: '{print $1}' "$meta_file"))
            types=($(awk -F: '{print $3}' "$meta_file"))
            constraints=($(awk -F: '{print $2}' "$meta_file"))

            values=()
            for ((i=0; i<${#columns[@]}; i++)); do
                while true; do
                    echo "Enter value for ${columns[i]} (${types[i]}): "
                    read -r value

                    if [[ ${types[i]} == "int" && ! $value =~ ^[0-9]+$ ]]; then
                        echo "Error: Value must be of type int."
                        continue
                    elif [[ ${types[i]} == "string" && ! $value =~ ^[a-zA-Z0-9_]+$ ]]; then
                        echo "Error: Value must be of type string."
                        continue
                    fi

                    if [[ ${constraints[i]} == "PK" ]]; then
                        if grep -q "^$value:" "$data_file"; then
                            echo "Error: Primary key must be unique."
                            continue
                        fi

                        if [[ ${types[i]} == "int" && ! $value =~ ^[0-9]+$ ]]; then
                            echo "Error: Primary key must be of type int."
                            continue
                        elif [[ ${types[i]} == "string" && ! $value =~ ^[a-zA-Z][a-zA-Z_0-9]*$ ]]; then
                            echo "Error: Primary key must be of type string."
                            continue
                        fi
                    fi

                    values+=("$value")
                    break
                done
            done

            echo "${values[*]}" | sed 's/ /:/g' >> "$data_file"
            echo "Values inserted successfully!"
            ;;
        $(($Table_count + 1)))
            echo "Operation cancelled."
            break
            ;;
        *)
            echo "Invalid choice. Try again."
            ;;
    esac
done
;;
    4)
    #select
TB_list=($(ls $HOME/.DataBase/$DBname))
Table_count=${#TB_list[@]}
select choice in "${TB_list[@]}" "Exit"; do
    case $REPLY in
        [1-$Table_count])
            data_file="$HOME/.DataBase/$DBname/$choice"
            meta_file="$HOME/.DataBase/$DBname/.${choice}_meta"

            columns=($(awk -F: '{print $1}' "$meta_file"))
            types=($(awk -F: '{print $3}' "$meta_file"))

            echo "--------- select from table ----------"
            select choice in select_all_rows select_specific_row select_by_column 'Exit'; do
                case $REPLY in
                1)
                rows=$(awk -F: '{print $0}' "$data_file" | wc -l)
                if [[ $rows == 0 ]]; then
                    echo "no rows found "
                else
                    awk -F: '{print $0}' "$data_file" | column -t -s:
                fi
                ;;
                2)
                echo "select specific row in $choice"
                for ((i=0; i<${#columns[@]}; i++)); do
                            echo "$((i+1)). ${columns[i]} (${types[i]})"
                        done

                        read -r -p "Enter the column number to apply condition: " col_num
                        if [[ $col_num < 1 || $col_num > ${#columns[@]} ]]; then
                            echo  "Invalid column number"
                            break
                        fi

                        col_name="${columns[$((col_num-1))]}"
                        col_type="${types[$((col_num-1))]}"

                        read -r -p "Enter the value to match in '$col_name': " value
                        if [[ col_type == "int" && ! $value =~ ^[0-9]+$ ]]; then
                            echo "Error: Value must be of type int."
                            continue
                        elif [[ col_type  == "string" && ! $value =~ ^[a-zA-Z0-9_]+$ ]]; then
                            echo "Error: Value must be of type string."
                            continue
                        fi
                        match_count=$(awk -F: -v col="$col_num" -v val="$value" '$col == val' "$data_file" | wc -l)
                        if [[ $match_count == 0 ]]; then
                            echo "No rows found matching '$col_name = $value'."
                        else
                            echo "Rows matching '$col_name = $value':"
                            awk -F: -v col="$col_num" -v val="$value" '$col == val' "$data_file" | column -t -s:
                        fi
                        ;;
                3)
                for ((i=0; i<${#columns[@]}; i++)); do
                    echo "$((i+1)). ${columns[i]} (${types[i]})"
                    done
                 read -r -p "Enter the column number to apply condition: " col_num
                 if [[ $col_num < 1 || $col_num > ${#columns[@]} ]]; then
                            echo  "Invalid column number"
                            break
                        fi
                awk -F: -v col="$col_num" '{print $col}' "$data_file" | column -t -s:

                ;;
                4)
                break
                ;;
                *)
                echo "Invalid choice."
                ;;

                esac
            done
        ;;
         $(($Table_count + 1)))
            echo "Operation cancelled."
            source db_table.sh
            ;;
        *)
            echo "Invalid choice. Try again."
            ;;
    esac
done

    ;;
    5)
    #delete
TB_list=($(ls $HOME/.DataBase/$DBname))
Table_count=${#TB_list[@]}
select choice in "${TB_list[@]}" "Exit"; do
    case $REPLY in
        [1-$Table_count])
            data_file="$HOME/.DataBase/$DBname/$choice"
            meta_file="$HOME/.DataBase/$DBname/.${choice}_meta"
            
            select choice in delete_all_rows delete_row delete_column "Exit"; do
                case $REPLY in
                    1)
                        if [[ -f "$data_file" ]]; then
                            > "$data_file"
                            echo "All rows deleted from $choice"
                        else
                            echo "$choice not found"
                        fi
                        ;;
                    2)
                        while true; do
                        pk_col=$(awk -F: '$2 == "PK" {print NR}' "$meta_file")
                        if [[ -z "$pk_col" ]]; then
                            echo "No primary key found"
                        else
                            awk -F: '{print $0}' "$data_file" | column -t -s:

                            read -r -p "Enter the PK value to delete: " pk_value

                            if ! grep -q "^$pk_value" "$data_file"; then
                                echo "No row with this PK: '$pk_value'"
                            else
                                sed -i "/^$pk_value:/d" "$data_file"
                                echo "Row was deleted"
                                break
                            fi
                        fi
                    done

                    ;;
                    3)
                        columns=($(awk -F: '{print $1}' "$meta_file"))
                        for ((i=0; i<${#columns[@]}; i++)); do
                            echo "$((i+1)). ${columns[i]}"
                        done

                        read -r -p "Enter the column number to apply condition: " col_num
                        if [[ $col_num -lt 1 || $col_num -gt ${#columns[@]} ]]; then
                            echo "Invalid column number."
                            break
                        fi

                        col_name="${columns[$((col_num-1))]}"
                        read -r -p "Enter the value to delete in column '$col_name': " value

                        
                        if awk -F: -v col="$col_num" -v val="$value" '$col == val' "$data_file" | grep -q "."; then
                            awk -F: -v col="$col_num" -v val="$value" '$col != val' "$data_file" > "$data_file.tmp" && mv "$data_file.tmp" "$data_file"
                            echo "Rows matching '$col_name = $value' have been deleted."
                        else
                            echo "No rows found matching '$col_name = $value'."
                        fi

                        break

                    ;;
                    4)
                        break
                        ;;
                    *)
                        echo -e "$Invalid choice"
                        ;;
                esac
            done
            ;;
        $(($Table_count + 1)))
            echo "Operation cancelled."
            source db_table.sh
            ;;
        *)
            echo "Invalid choice. Try again."
            ;;
    esac
done




    ;;
    6)
    #update

TB_list=($(ls $HOME/.DataBase/$DBname))
Table_count=${#TB_list[@]}
select choice in "${TB_list[@]}" "Exit"; do
    case $REPLY in
        [1-$Table_count])
            data_file="$HOME/.DataBase/$DBname/$choice"
            meta_file="$HOME/.DataBase/$DBname/.${choice}_meta"
            columns=($(awk -F: '{print $1}' "$meta_file"))

            select choice in UpdateAll Update_Specific_row "Exit";do
            case $REPLY in

            1)
            awk -F: '{print $0}' "$data_file" | column -t -s:
            read -r -p "Enter value to update: " val
            read -r -p "Enter the update: " up
            flag=$(awk -F : -v value="$val" 'BEGIN{f=1}{for(i=1;i<=NF;i++){if(value==$i){f=0}}}END{print f}' "$data_file")                
            if [[ $flag = 0 ]]; then
                sed -i 's/'$val'/'$up'/g' "$data_file"
                echo "done"
            else
                echo "the value you want to replace do not exist"
            fi
            ;;
            2)
            awk -F: '{print $0}' "$data_file" | column -t -s:
            read -r -p "Enter the PK of the row : " pk
            read -r -p "Enter value to update: " val
            cut -d : -f 1 "$data_file" | grep $val > /dev/null
            if [ $? = 0 ]; then
                echo "Cannot Update Primary Key"
                break
            fi                       
            read -r -p "Enter the update: " up
            row=$(awk -F : -v primaryk=$pk '{if($1==primaryk){print NR}}' "$data_file")
            flag=$(awk -F : -v value="$val" 'BEGIN{f=1}{for(i=1;i<=NF;i++){if(value==$i){f=0}}}END{print f}' "$data_file")
            if [[ -n $row  ]]; then
                if [[ $flag = 0 ]]; then
                    sed -i "${row} s/$val/$up/" "$data_file"
                    echo "value updated"
                else
                    echo "There is no such value"
                fi
            else
                echo "Not valid PK"
            fi
            ;;
            3)
            break
                ;;
                *)
                    echo "Not a valid choice"
            esac
            done
        
        ;;
        $(($Table_count + 1)))
            echo "Operation cancelled."
            source db_table.sh
            ;;
        *)
            echo "Invalid choice. Try again."
            ;;
    esac
done
    ;;
    7)
    #list
    ls $HOME/.DataBase/$DBname

    ;;
    8)
    source db_menu.sh

    ;;
    *)
    echo "Invalid choice. Try again."

    ;;
    esac

done

