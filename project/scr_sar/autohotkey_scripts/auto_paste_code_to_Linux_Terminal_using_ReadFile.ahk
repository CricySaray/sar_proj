#NoEnv
#SingleInstance Force

; Global flag: control send status
Global IsSending := 0

; Mouse side button (XButton1) trigger
~XButton1::
    ; ==== ONLY MODIFY THIS LINE ====
    ; 示例1：Windows本地路径（二选一）
    ; FilePath := "C:\test.vimrc"  
    ; 示例2：WSL UNC路径（替换为你的实际路径）
    FilePath := "\\wsl.localhost\Ubuntu-22.04\home\aidensong\project/scr_sar/tcl/flow_build/invs_flow/all_genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation.invs.tcl "
    
    ; ========== 核心修改：复用能正常读取的FileRead逻辑 ==========
    ; 移除原有的引号包裹 + 用参考代码的纯文本读取方式（*t 后直接跟变量）
    FileRead, FileContent, *t %FilePath%
    
    ; 检查文件读取结果（复用参考代码的错误提示逻辑）
    if ErrorLevel {
        MsgBox % "File read failed!`nPath: " FilePath
        return
    }
    
    ; Start sending
    IsSending := 1
    LineNum := 0
    ; ========== 兼容修改：改用参考代码的StrSplit拆分行（避免Loop Parse兼容问题） ==========
    lines := StrSplit(FileContent, "`n", "`r")
    
    ; 逐行发送（保留停止/睡眠/提示逻辑）
    for index, line in lines {
        ; Stop immediately if flag is 0
        if (IsSending = 0) {
            ToolTip % "Stopped at line " LineNum
            SetTimer, RemoveToolTip, -1500
            break
        }
        
        ; Send plain text (复用参考代码的{Text}模式)
        SendInput {Text}%line%
        SendInput {Enter}
        LineNum += 1
        
        ; Sleep every 1000 lines
        if (Mod(LineNum, 400) = 0) {
            ToolTip % "Sent " LineNum " lines - sleep 1s..."
            SetTimer, RemoveToolTip, -1000
            Sleep 15000
        }
        Sleep 10
    }
    
    ; Completion tip
    if (IsSending = 1) {
        ToolTip % "Done! Total lines: " LineNum
        SetTimer, RemoveToolTip, -2000
    }
    IsSending := 0
return

; Stop shortcut: Ctrl+Alt+Esc（完全保留）
^!Esc::
    IsSending := 0
    ToolTip % "Output stopped!"
    SetTimer, RemoveToolTip, -1500
return

; 自定义标签：关闭所有ToolTip（完全保留）
RemoveToolTip:
    ToolTip
return
