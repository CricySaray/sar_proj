-- =============================================================================
--  abbreviations.lua
--  迁移自原 vimrc 的所有 iabbrev / cabbrev。
--  nvim 中通过 vim.cmd 直接调用 vimscript 的 :iabbrev / :cabbrev。
--
--  转义说明：
--  - lua 字符串里的 `\\` 在传给 vim 后会变成一个字面 `\`
--  - 因此原 vimrc 里的 `\\`（vim regex 匹配字面反斜杠）在 lua 中要写成 `\\\\`
-- =============================================================================

local function iabbr(lhs, rhs)
  vim.cmd("iabbrev " .. vim.fn.escape(lhs, " |") .. " " .. rhs)
end

local function cabbr(lhs, rhs)
  vim.cmd("cabbrev " .. vim.fn.escape(lhs, " |") .. " " .. rhs)
end

-- -----------------------------------------------------------------------------
--  插入模式缩写
-- -----------------------------------------------------------------------------
iabbr("ec", "ecoChangeCell")
iabbr("ea", "ecoAddRepeater")
iabbr("ed", "ecoDeleteRepeater")

-- -----------------------------------------------------------------------------
--  命令行模式缩写
-- -----------------------------------------------------------------------------
cabbr("GG",          "%!grep -B1 -A1")
cabbr("bwp",         "v/BWP/d")
cabbr("a",           "%!awk '{print }'")
cabbr("12",          "%!awk '{print $1,$2}'")
cabbr(")",           "%s/(\\|)//g")
cabbr("ch12",        "%!awk '{print $2,$1}'")
cabbr("rmulvt",      "g/CPDULVT/d")
cabbr("rmpinm",      "%s/\\/\\w\\+ / /")
cabbr("rmpine",      "%s/\\/\\w\\+$//")
cabbr("lvtm",        "%s/CPD /CPDLVT /")
cabbr("lvte",        "%s/CPD$/CPDLVT/")
cabbr("ulvtm",       "%s/CPDLVT /CPDULVT /")
cabbr("ulvte",       "%s/CPDLVT$/CPDULVT/")
cabbr("t16",         "%s/T\\d\\dP96/T16P96/")
cabbr("ec",          "%!awk '{print \"ecoChangeCell -cell\",$1,\"-inst\",$2}'")
cabbr("sc",          "%!awk '{print \"size_cell\",$2,$1}'")
cabbr("inst",        "%s/\\\\(.*\\\\)\\\\/.*/\\\\1/g")
cabbr("vv",          "vs ~/.vimrc")
cabbr("ess",         "v/endpoint:\\|startpoint:\\|slack (/d")
cabbr("formatslack", "%!awk '$1 ~ /slack/ {print $1,$2,$3 ; next} 1'")
cabbr("re",          "r ~/project/scr_sar/ref_content/setEcoMode.tcl")
cabbr("ahk",         "r ~/project/scr_sar/ref_content/autohotkey_template_paste_longstring.ahk")
cabbr("dp",          "r ~/project/scr_sar/ref_content/define_proc_arguments.tcl")
cabbr("pdp",         "r ~/project/scr_sar/ref_content/define_perl_options.txt")
