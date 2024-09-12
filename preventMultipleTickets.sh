#!/bin/bash

# Function to get user input with language support
get_input() {
    if [ "$LANGUAGE" = "zh" ]; then
        read -p "$1 " REPLY
    else
        read -p "$2 " REPLY
    fi
    echo $REPLY
}

# Function to display messages with language support
display_message() {
    if [ "$LANGUAGE" = "zh" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

# Function to install the prevention system
install_prevention_system() {
    # Prompt for WHMCS installation directory
    WHMCS_DIR=$(get_input "请输入WHMCS安装目录：" "Enter WHMCS installation directory: ")

    # Check if directory exists
    if [ ! -d "$WHMCS_DIR" ]; then
        display_message "目录不存在。安装失败。" "Directory does not exist. Installation failed."
        exit 1
    fi

    # Create hooks directory if it doesn't exist
    HOOKS_DIR="$WHMCS_DIR/includes/hooks"
    mkdir -p "$HOOKS_DIR"

    # Create the prevention hook files
    PRE_SUBMIT_FILE="$HOOKS_DIR/preventMultipleTicketsPreSubmit.php"
    POST_SUBMIT_FILE="$HOOKS_DIR/preventMultipleTicketsPostSubmit.php"

    # Create preventMultipleTicketsPreSubmit.php
    cat > "$PRE_SUBMIT_FILE" << EOL
<?php

use WHMCS\Database\Capsule;

function checkOpenTicketsPreSubmit(\$clientId) {
    return Capsule::table('tbltickets')
        ->where('userid', \$clientId)
        ->whereIn('status', ['Open', 'Answered', 'Customer-Reply', 'In Progress'])
        ->count();
}

function preventMultipleTicketsPreSubmit(\$vars) {
    global \$_LANG;

    if (!isset(\$_SESSION['uid'])) {
        return \$vars;
    }

    \$clientId = \$_SESSION['uid'];
    \$openTicketsCount = checkOpenTicketsPreSubmit(\$clientId);

    if (\$openTicketsCount > 0) {
        \$vars['errormessage'] = \$_LANG['preventMultipleTicketsError'];
        error_log('Error message set for user ' . \$clientId . ' with ' . \$openTicketsCount . ' open tickets.');
    }

    return \$vars;
}

add_hook('ClientAreaPageSubmitTicket', 1, 'preventMultipleTicketsPreSubmit');
EOL

    # Create preventMultipleTicketsPostSubmit.php
    cat > "$POST_SUBMIT_FILE" << EOL
<?php

use WHMCS\Database\Capsule;
use WHMCS\Exception\ProgramExit;

function checkOpenTicketsPostSubmit(\$clientId) {
    return Capsule::table('tbltickets')
        ->where('userid', \$clientId)
        ->whereIn('status', ['Open', 'Answered', 'Customer-Reply', 'In Progress'])
        ->count();
}

function preventMultipleTicketsPostSubmit(\$vars) {
    global \$_LANG;

    if (!isset(\$_SESSION['uid'])) {
        return \$vars;
    }

    \$clientId = \$_SESSION['uid'];
    \$openTicketsCount = checkOpenTicketsPostSubmit(\$clientId);

    if (\$openTicketsCount > 1) {
        error_log('Preventing ticket creation for user ' . \$clientId . ' with ' . \$openTicketsCount . ' open tickets.');
        throw new ProgramExit(\$_LANG['preventMultipleTicketsError']);
    }

    return \$vars;
}

add_hook('TicketOpenValidation', 1, 'preventMultipleTicketsPostSubmit');
EOL

    display_message "预防钩子已安装到 $PRE_SUBMIT_FILE 和 $POST_SUBMIT_FILE" "Prevention hooks installed to $PRE_SUBMIT_FILE and $POST_SUBMIT_FILE"

    # Add translations
    declare -A translations=(
        ["chinese-tw.php"]="\$_LANG['preventMultipleTicketsError'] = '您已經有一個未解決的工單。請先解決現有工單，再開立新工單。';"
        ["chinese.php"]="\$_LANG['preventMultipleTicketsError'] = '您已经有一个未解决的工单。请先解决现有工單，再创建新工單。';"
        ["english.php"]="\$_LANG['preventMultipleTicketsError'] = 'You already have an open ticket. Please resolve your existing ticket before opening a new one.';"
        ["farsi.php"]="\$_LANG['preventMultipleTicketsError'] = 'شما قبلاً یک درخواست باز دارید. لطفاً ابتدا درخواست موجود خود را حل کنید سپس یک درخواست جدید باز کنید.';"
        ["japanese.php"]="\$_LANG['preventMultipleTicketsError'] = '既に未解決のチケットがあります。既存のチケットを解決してから新しいチケットを開いてください。';"
        ["spanish.php"]="\$_LANG['preventMultipleTicketsError'] = 'Ya tienes un ticket abierto. Por favor, resuelve tu ticket existente antes de abrir uno nuevo.';"
        ["vietnamese.php"]="\$_LANG['preventMultipleTicketsError'] = 'Bạn đã có một yêu cầu đang mở. Vui lòng giải quyết yêu cầu hiện có trước khi mở một yêu cầu mới.';"
    )

    LANG_DIR="$WHMCS_DIR/lang/overrides"
    mkdir -p "$LANG_DIR"
    for file in "${!translations[@]}"; do
        LANG_FILE="$LANG_DIR/$file"
        if [ ! -f "$LANG_FILE" ]; then
            echo "<?php" > "$LANG_FILE"
        fi
        echo "${translations[$file]}" >> "$LANG_FILE"
        display_message "翻译已添加到 $LANG_FILE" "Translation added to $LANG_FILE"
    done

    display_message "安装完成。" "Installation complete."
}

# Function to remove the prevention system
remove_prevention_system() {
    WHMCS_DIR=$(get_input "请输入WHMCS安装目录：" "Enter WHMCS installation directory: ")

    # Remove hook files
    PRE_SUBMIT_FILE="$WHMCS_DIR/includes/hooks/preventMultipleTicketsPreSubmit.php"
    POST_SUBMIT_FILE="$WHMCS_DIR/includes/hooks/preventMultipleTicketsPostSubmit.php"

    if [ -f "$PRE_SUBMIT_FILE" ]; then
        rm "$PRE_SUBMIT_FILE"
        display_message "预防钩子已移除。" "Prevention hook file removed: $PRE_SUBMIT_FILE"
    fi

    if [ -f "$POST_SUBMIT_FILE" ]; then
        rm "$POST_SUBMIT_FILE"
        display_message "预防钩子已移除。" "Prevention hook file removed: $POST_SUBMIT_FILE"
    fi

    # Remove translations
    LANG_DIR="$WHMCS_DIR/lang/overrides"
    for file in "chinese-tw.php" "chinese.php" "english.php" "farsi.php" "japanese.php" "spanish.php" "vietnamese.php"; do
        LANG_FILE="$LANG_DIR/$file"
        if [ -f "$LANG_FILE" ]; then
            sed -i '/\$_LANG\['\''preventMultipleTicketsError'\''\]/d' "$LANG_FILE"
            display_message "从 $LANG_FILE 中移除了翻译。" "Translation removed from $LANG_FILE."
        fi
    done

    display_message "移除完成。" "Removal complete."
}

# Main script
display_message "WHMCS工单预防系统安装脚本" "WHMCS Ticket Prevention System Installation Script"
display_message "请选择语言 / Please select language:" "请选择语言 / Please select language:"
display_message "1. 中文" "1. 中文"
display_message "2. English" "2. English"
LANG_CHOICE=$(get_input "输入选项：" "Enter choice: ")

if [ "$LANG_CHOICE" = "1" ]; then
    LANGUAGE="zh"
else
    LANGUAGE="en"
fi

while true; do
    if [ "$LANGUAGE" = "zh" ]; then
        echo "1. 安装预防系统"
        echo "2. 移除预防系统"
        echo "3. 修改安装路径"
        echo "4. 退出"
        ACTION=$(get_input "请选择操作：" "")
    else
        echo "1. Install prevention system"
        echo "2. Remove prevention system"
        echo "3. Modify installation path"
        echo "4. Exit"
        ACTION=$(get_input "" "Select action: ")
    fi

    case $ACTION in
        1) install_prevention_system ;;
        2) remove_prevention_system ;;
        3) WHMCS_DIR=$(get_input "请输入新的WHMCS安装目录：" "Enter new WHMCS installation directory: ") ;;
        4) break ;;
        *) display_message "无效选项，请重试。" "Invalid option, please try again." ;;
    esac
done

display_message "脚本已结束。" "Script ended."
