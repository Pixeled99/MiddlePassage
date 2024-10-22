SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AUDIO_FILE="$SCRIPT_DIR/sounds/song.mp3"

FIGLET_FILE="$SCRIPT_DIR/libraries/figlet_local/figlet -d $SCRIPT_DIR/libraries/figlet_local/fonts"

RESIZE_FILE="$SCRIPT_DIR/libraries/resize"

MPV_FILE="$SCRIPT_DIR/libraries/mpv.app/Contents/MacOS/mpv"

chmod +x "$SCRIPT_DIR/libraries/figlet_local/figlet"
chmod +x $RESIZE_FILE
chmod +x $MPV_FILE

type () {
    local string=$1
    for (( i=0; i<${#string}; i++ )); do
        if [[ ${string:$i:1} != " " ]] && (( $(echo "$2 > 0" | bc -l) )); then
            $MPV_FILE --speed=1.5 "$SCRIPT_DIR/sounds/$(( $RANDOM % 4 + 1)).mp3" &> /dev/null &
        fi
        printf "${string:$i:1}"
        sleep $2
    done
    if (( $(echo "$2 == 0" | bc -l) )); then
        $MPV_FILE --speed=1.5 "$SCRIPT_DIR/sounds/$(( $RANDOM % 4 + 1)).mp3" &> /dev/null &
    fi
    sleep $3
    if [[ $4 -ne $zero ]]; then
        echo
    fi
}

user () {
    tput cnorm
    stty echo
}

other () {
    tput civis
    stty -echo
}

yN () {
    while (true); do
        other
        type "$1 (y/N)" 0.15 0 1
        user
        read -r answer
        local input=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [[ "$input" == "y" || "$input" == "n" ]]; then
            if [[ "$input" == "y" ]]; then
                return 1
            elif [[ "$input" == "n" ]]; then
                return 0
            fi
        else
            other
            type "What?" 0.15 0 1
        fi
    done
}


$RESIZE_FILE -s 50 200

COLUMNS=$(tput cols)
ROWS=$(tput lines)

other

row_length=$((COLUMNS - ROWS - 1))

if [ $row_length -lt 1 ]; then
    row_length=1
fi

declare -a screen

index=$(($ROWS-1))

for ((i = 0; i < (( ROWS / 2 )); i++)); do
    screen[0]+=" "
    screen[$index]+=" "
done

screen[0]+="/"
screen[0]+=$(printf "%${row_length}s" | tr " " "-")
screen[0]+="\\"

screen[$index]+="\\"
screen[$index]+=$(printf "%${row_length}s" | tr " " "-")
screen[$index]+="/"

line=$(((ROWS - 4) / 2 - 1))

width=$(($row_length + line * 2))

text_string=$($FIGLET_FILE -w $width -f big Middle Passage)

declare -a text_array

IFS=$'\n' read -r -d '' -a text_array <<< "$text_string"$'\0'

if [ ${#text_array[@]} -gt 8 ]; then
    echo "Your window is too small"
    exit
fi

for ((j = 1; j < (( ROWS - 1 )); j++)); do
    if [[ "$j" -lt $((ROWS / 2)) ]]; then
        row_length=$((row_length + 2))
        screen[$j]+=$(printf "%$(((ROWS / 2) - j))s")
        screen[$j]+="/"
        if [[ "$j" -ge $line ]]; then
            text_length=${#text_array[$(($j - line))]}
            left_padding=$(( (row_length - text_length) / 2 ))
            right_padding=$(( row_length - text_length - left_padding ))
            screen[$j]+=$(printf "%${left_padding}s")
            screen[$j]+="${text_array[$(($j - line))]}"
            screen[$j]+=$(printf "%${right_padding}s")
        else
            screen[$j]+=$(printf "%${row_length}s")
        fi
        screen[$j]+="\\"
    elif [[ "$j" -gt $((ROWS / 2)) ]]; then
        if [[ $(($ROWS % 2)) -ne 0 ]]; then
            screen[$j]+=$(printf "%$(((ROWS / 2) - j))s")
        else
            screen[$j]+=$(printf "%$(((ROWS / 2) - j - 1))s")
        fi
        screen[$j]+="\\"
        text_length=${#text_array[$((j - line))]}
        left_padding=$(( (row_length - text_length) / 2 ))
        right_padding=$(( row_length - text_length - left_padding ))
        
        if [[ left_padding < 0 ]]; then
            left_padding=0
        fi
        if [[ right_padding < 0 ]]; then
            right_padding=0
        fi
        
        screen[$j]+=$(printf "%${left_padding}s")
        screen[$j]+="${text_array[$((j - line))]}"
        screen[$j]+=$(printf "%${right_padding}s")
        screen[$j]+="/"
        row_length=$((row_length - 2))
    else
        if [[ $(($ROWS % 2)) -ne 0 ]]; then
            screen[$j]+="| "
            
            text_length=${#text_array[0]}
            left_padding=$(( (row_length - text_length) / 2 ))
            right_padding=$(( row_length - text_length - left_padding ))
            
            if (( left_padding < 0 )); then
                left_padding=0
            fi
            if (( right_padding < 0 )); then
                right_padding=0
            fi
            
            screen[$j]+=$(printf "%${left_padding}s")
            screen[$j]+="${text_array[$((j - line))]}"
            screen[$j]+=$(printf "%${right_padding}s")
            
            screen[$j]+=" |"
        else
            screen[$j]+=$(printf "%$(((ROWS / 2) - j + 1))s")
            screen[$j]+="\\"
            text_length=${#text_array[$((j - line))]}
            left_padding=$(( (row_length - text_length) / 2 ))
            right_padding=$(( row_length - text_length - left_padding ))
            
            if [[ left_padding < 0 ]]; then
                left_padding=0
            fi
            if [[ right_padding < 0 ]]; then
                right_padding=0
            fi
            
            screen[$j]+=$(printf "%${left_padding}s")
            screen[$j]+="${text_array[$((j - line))]}"
            screen[$j]+=$(printf "%${right_padding}s")
            screen[$j]+="/"
            row_length=$((row_length - 2))
        fi
    fi
done

y=0
x=0
done=0

for (( i=0; i<${#screen[@]}-1; i++ )); do
    echo "${screen[$i]}"
done
printf '%s' "${screen[$index]}"
$MPV_FILE --loop $AUDIO_FILE &> /dev/null &
MPV_PID=$!
read -n 1 -s -r -p ""

while [[ $done -eq $zero ]];
do 
    clear
    for ((i = 0; i < ((ROWS / 5)); i++)); do
        if [[ $((y+i)) -eq $ROWS ]]; then
            break
        fi
        row=${screen[$((y+i))]}
        screen[$((y+i))]="${row:0:$x}#${row:$((x + 1))}"
    done
    x=$((x+1))
    if [[ $x -eq $COLUMNS ]]; then
        y=$((y+i))
        x=0
    fi
    if [[ $y -gt $index ]]; then
        done=1
    fi
    for (( i=0; i<${#screen[@]}-1; i++ )); do
        echo "${screen[$i]}"
    done
    printf '%s' "${screen[$index]}"
    sleep 0.005
done
sleep 4
clear
sleep 3
printf "%-$((COLUMNS*ROWS))s" "" | tr " " "#"
sleep 2
clear
printf "%-$((COLUMNS*ROWS))s" "" | tr " " "#"
sleep 1
clear
for (( j=0; j<10; j++)); do 
    sleep $(echo "0.1 - $j / 120" | bc -l)
    printf "%-$((COLUMNS*ROWS))s" "" | tr " " "#"
    sleep $(echo "0.1 - $j / 120" | bc -l)
    clear
done
for (( j=0; j<10; j++)); do 
    sleep 0.025
    printf "%-$((COLUMNS*ROWS))s" "" | tr " " "#"
    sleep 0.025
    clear
done
sleep 3
kill $MPV_PID
sleep 3

other 

type Hello? 0.15 3 1
type "Is anybody there?" 0.15 4 1

sure=0
while [[ $sure -eq $zero ]];
do 
    other
    type "Who are " 0.15 2 0
    printf "\033[1m"
    type "you?" 0.0 5 1
    printf "\033[22m"
    user
    read -r name
    yN "Are you sure?"
    sure=$?
done

other
sleep 1
yes=1
while [[ $yes -ne $zero ]];
do
    yN "$name, will we ever get to see home again?"
    yes=$?
    if [[ $yes -ne $zero ]]; then
        echo "#ERROR#"
        other
        sleep 2
    fi
done

other
sleep 1
type "Oh..." 0.5 2 1
printf "\033[31;1m"
type "What is going on down there?!?" 0.10 2 1
printf "\033[39;22m"
type "Go $name, while you can" 0.15 2 1
printf "\033[31;1m"
type "YOU'VE DONE IT NOW" 0.10 2 1
printf "\033[39;22m"
type "Tell me $name," 0.25 1 0
type " are we all doomed" 0.15 0 0
type " on the" 0.2 0 0
printf "\033[1m"
type " Middle Passage?" 0.3 0 1
printf "\033[22m"
user
read -n 1 -s -r -p ""
clear