#!/bin/csh -f
#===============================================================================
# makerun.csh
#
# 用途：创建新的 PR (Place & Route) run 目录，搭建标准后端流程目录结构，
#       复制/链接标准流程脚本与配置模板，注入项目设置，
#       并支持从已有 run 复制配置，或从指定步骤续跑。
#
# 依据：summary_for_makerun.csh.sum（需求编号 REQ-xxx / REQ-CON-xxx 见各段注释）
#
# 用法（唯一合法形式）：
#   makerun.csh <suffix> [-f <source_run_path>] [<start_step>]
#
# 三种模式：
#   1) makerun.csh <suffix>                          创建全新空 run
#   2) makerun.csh <suffix> -f <src_run>             从源 run 复制完整配置（完整重启）
#   3) makerun.csh <suffix> -f <src_run> <start_step> 从指定步骤起步（复制配置 + DB 链接 + marker）
#      start_step 严格属于 { preplace, place, ccopt, route }
#
# 步骤→DB 映射（REQ-008）：
#   start_step | 链接的源 run 输入 DB（成对，绝对路径 symlink）   | touch 的 marker
#   (无)       | 无                                             | 无
#   preplace   | PR/DB/init.enc + PR/DB/init.enc.dat            | init
#   place      | PR/DB/preplace.enc + PR/DB/preplace.enc.dat    | init preplace
#   ccopt      | PR/DB/place_opt_design.enc + (.dat)            | init preplace place
#   route      | PR/DB/ccopt_opt.enc + (.dat)                   | init preplace place ccopt
#
# 【运行前必填】脚本顶部的配置占位变量区：block / TEMPLATE_DIR /
#   foundry_setting / project_setting / user_libpath_setting / MARKER_DIR /
#   以及模式 2/3 用到的 src_* 配置位置变量。
#===============================================================================

#===============================================================================
# 0. 配置占位变量区
#    [ASSUMPTION-A/B/C/E/F] —— 源描述未明确，已与使用者确认的处理方式见各变量注释。
#    未填写的项会给出 WARNING 或 ERROR（见对应检查）。
#===============================================================================

# [ASSUMPTION-A] REQ-001：项目(block)名称。
#   源描述仅说"根据当前工作路径自动检测项目"，未说明取 $PWD 中哪一段。
#   已与使用者确认：采用"脚本内占位变量"方式，运行前请填写；留空则报错退出。
#   （如需恢复自动检测，可启用下行并删除上方占位： set block = `basename $PWD` ）
set block = ""

# [ASSUMPTION-B] REQ-003：标准流程脚本与配置模板的来源目录。
#   源描述未给出清单与来源目录；已与使用者确认：采用占位变量。
#   脚本会把该目录下所有内容复制到新 run 根目录。留空则跳过 REQ-003 并 WARNING。
set TEMPLATE_DIR = ""

# [ASSUMPTION-C] REQ-004：foundry / project / user libpath 三类项目设置的注入方式。
#   已与使用者确认：采用环境变量（setenv）方式。以下为占位值，请填写实际设置。
#   注意：环境变量名 FOUNDRY / PROJECT / USER_LIBPATH 为假设名（ASSUMPTION），可按需修改；
#   setenv 只对脚本进程及其子进程生效，不会影响调用方的 shell。
set foundry_setting      = ""
set project_setting      = ""
set user_libpath_setting = ""

# [ASSUMPTION-E] REQ-007：stage marker 文件存放目录（相对新 run 根目录）。
#   源描述未给路径；已与使用者确认：采用占位变量。summary 建议值为新 run 的 PR 目录（即填 PR）。
#   marker 文件名 = 步骤名（无扩展名）。留空则模式 3 不 touch marker 并 WARNING。
set MARKER_DIR = ""

# [ASSUMPTION-F] REQ-006：模式 2/3 复制后"更新所有路径"的规则。
#   采用 summary 建议值：把所复制内容中的"源 run 绝对路径"替换为"新 run 绝对路径"。
#   若实际需要替换的字段与此不同，请修改第 7.6 节替换段。

# 源 run 中 5 项配置的位置（相对源 run 根目录）。源描述未说明，以下为占位路径，
# 请按实际 flow 核对。SCB/STA 配置的清单与位置尤其需要确认（ASSUMPTION）。
set src_settings_tcl = "settings.tcl"
set src_user_lib     = "User_lib_list.tcl"
set src_user_plug    = "user_plug"
set src_scb_configs  = "SCB"
set src_sta_configs  = "STA"

#===============================================================================
# 1. 命令行解析与合法性校验
#    （违反约束必须报错退出，且不创建任何文件）
#===============================================================================

# 必选参数 <suffix> 位于第 1 个位置
if ( $#argv < 1 ) then
  echo "ERROR [makerun]: 缺少必选参数 <suffix>" >& /dev/stderr
  exit 1
endif
set suffix = "$1"

set use_f      = 0
set src_run    = ""
set start_step = ""
set pending_src = 0

set i = 2
while ( $i <= $#argv )
  if ( "$argv[$i]" == "-f" ) then
    set use_f = 1
    set pending_src = 1
  else if ( $pending_src ) then
    set src_run = "$argv[$i]"
    set pending_src = 0
  else if ( "$start_step" == "" ) then
    set start_step = "$argv[$i]"
  else
    echo "ERROR [makerun]: 参数过多，无法解析（唯一合法形式见脚本头部）" >& /dev/stderr
    exit 1
  endif
  @ i = $i + 1
end

# 提供 -f 但缺少 source_run_path（含 -f 作为最后一个参数的情况）
if ( $pending_src ) then
  echo "ERROR [makerun]: -f 后必须紧跟 source_run_path" >& /dev/stderr
  exit 1
endif

# REQ-CON-001：start_step 不允许在缺少 -f 时出现
if ( "$start_step" != "" && ! $use_f ) then
  echo "ERROR [makerun]: start_step '$start_step' 只能在提供 -f 时使用 (REQ-CON-001)" >& /dev/stderr
  exit 1
endif

# REQ-CON-004：start_step 的值必须严格属于 {preplace, place, ccopt, route}
if ( "$start_step" != "" ) then
  switch ( "$start_step" )
    case "preplace":
    case "place":
    case "ccopt":
    case "route":
      breaksw
    default:
      echo "ERROR [makerun]: 非法 start_step '$start_step' (REQ-CON-004)" >& /dev/stderr
      exit 1
  endsw
endif

# suffix 必选（不允许为空）
if ( "$suffix" == "" ) then
  echo "ERROR [makerun]: 缺少必选参数 <suffix>" >& /dev/stderr
  exit 1
endif

# [ASSUMPTION-A] block 占位变量未填写
if ( "$block" == "" ) then
  echo "ERROR [makerun]: 未设置 block 名称，请在脚本顶部占位变量处填写 (ASSUMPTION-A)" >& /dev/stderr
  exit 1
endif

# 模式 2/3：提前校验源 run 存在（在创建任何内容之前，避免半途失败）
if ( $use_f && ! -d "$src_run" ) then
  echo "ERROR [makerun]: 源 run 目录不存在: $src_run" >& /dev/stderr
  exit 1
endif

#===============================================================================
# 2. 确定模式
#===============================================================================
if ( ! $use_f ) then
  set mode = "1 全新空 run"
else if ( "$start_step" == "" ) then
  set mode = "2 从源 run 复制完整配置"
else
  set mode = "3 从步骤 $start_step 起步"
endif

echo "==> makerun: block=$block suffix=$suffix mode=$mode"

#===============================================================================
# 3. 计算 run 目录名（REQ-001 / REQ-005）与绝对路径
#    新 run 目录名严格为: <block>_<MMDD>_<HHMM>_<suffix>
#===============================================================================
set MMDD = `date +%m%d`
set HHMM = `date +%H%M`
set run_dir    = "${block}_${MMDD}_${HHMM}_${suffix}"
set new_run_abs = "$PWD/$run_dir"

echo "==> 新 run 目录: $run_dir"

if ( -e "$run_dir" ) then
  echo "WARNING: 目录已存在: $run_dir（继续执行，同名文件将被覆盖）" >& /dev/stderr
endif

#===============================================================================
# 4. REQ-002 创建标准目录结构（幂等：目录已存在不报错）
#===============================================================================
foreach d ( PR PV STA FM PI signoff_check )
  mkdir -p "$run_dir/$d"
end
# PR/DB 供模式 3 的 DB 符号链接使用；模式 1/2 中保持为空（见 REQ-006 / RULE-4）
mkdir -p "$run_dir/PR/DB"

#===============================================================================
# 5. REQ-003 复制/链接标准流程脚本与配置模板
#    [ASSUMPTION-B] 模板来源为占位变量 TEMPLATE_DIR；此处用复制（cp -rp），
#    如需"链接"可改为 ln -s。留空则跳过并 WARNING。
#===============================================================================
if ( "$TEMPLATE_DIR" != "" ) then
  if ( ! -d "$TEMPLATE_DIR" ) then
    echo "WARNING [ASSUMPTION-B]: 模板目录不存在: $TEMPLATE_DIR，跳过 REQ-003" >& /dev/stderr
  else
    cp -rp "$TEMPLATE_DIR/." "$run_dir/"
    echo "==> 已从模板目录复制标准脚本/模板: $TEMPLATE_DIR"
  endif
else
  echo "WARNING [ASSUMPTION-B]: TEMPLATE_DIR 未配置，跳过 REQ-003（请在脚本顶部填写）" >& /dev/stderr
endif

#===============================================================================
# 6. REQ-004 注入项目设置（foundry / project / user libpath）
#    [ASSUMPTION-C] 已确认注入方式为环境变量。
#===============================================================================
if ( "$foundry_setting" == "" || "$project_setting" == "" || "$user_libpath_setting" == "" ) then
  echo "WARNING [ASSUMPTION-C]: foundry / project / user libpath 占位值未全部填写" >& /dev/stderr
endif
setenv FOUNDRY      "$foundry_setting"
setenv PROJECT      "$project_setting"
setenv USER_LIBPATH "$user_libpath_setting"
echo "==> 已注入环境变量: FOUNDRY=$FOUNDRY PROJECT=$PROJECT USER_LIBPATH=$USER_LIBPATH"

#===============================================================================
# 7. 模式 2/3：从源 run 复制完整配置（REQ-006），并改写所有路径（[ASSUMPTION-F]）
#===============================================================================
if ( $use_f ) then

  # 计算源 run 的绝对路径（用于路径改写与 symlink 的绝对路径 target）
  set oldpwd = `pwd`
  cd "$src_run"
  set src_abs = `pwd`
  cd "$oldpwd"
  echo "==> 源 run 绝对路径: $src_abs"

  set copied_files = ()

  # 7.1 settings.tcl
  if ( -e "$src_run/$src_settings_tcl" ) then
    cp -p "$src_run/$src_settings_tcl" "$run_dir/"
    set copied_files = ( $copied_files "$run_dir/$src_settings_tcl" )
  else
    echo "WARNING: 源 run 中缺少 $src_settings_tcl，跳过" >& /dev/stderr
  endif

  # 7.2 User_lib_list.tcl
  if ( -e "$src_run/$src_user_lib" ) then
    cp -p "$src_run/$src_user_lib" "$run_dir/"
    set copied_files = ( $copied_files "$run_dir/$src_user_lib" )
  else
    echo "WARNING: 源 run 中缺少 $src_user_lib，跳过" >& /dev/stderr
  endif

  # 7.3 user_plug
  #     [ASSUMPTION-D] 源描述未说明是文件还是目录，两种都处理。
  if ( -e "$src_run/$src_user_plug" ) then
    if ( -d "$src_run/$src_user_plug" ) then
      cp -rp "$src_run/$src_user_plug" "$run_dir/"
      foreach cf ( `find "$run_dir/$src_user_plug" -type f` )
        set copied_files = ( $copied_files $cf )
      end
    else
      cp -p "$src_run/$src_user_plug" "$run_dir/"
      set copied_files = ( $copied_files "$run_dir/$src_user_plug" )
    endif
  else
    echo "WARNING: 源 run 中缺少 $src_user_plug，跳过" >& /dev/stderr
  endif

  # 7.4 SCB configs（来源与清单待确认，见顶部 src_scb_configs 占位变量）
  if ( -e "$src_run/$src_scb_configs" ) then
    if ( -d "$src_run/$src_scb_configs" ) then
      cp -rp "$src_run/$src_scb_configs" "$run_dir/"
      foreach cf ( `find "$run_dir/$src_scb_configs" -type f` )
        set copied_files = ( $copied_files $cf )
      end
    else
      cp -p "$src_run/$src_scb_configs" "$run_dir/"
      set copied_files = ( $copied_files "$run_dir/$src_scb_configs" )
    endif
  else
    echo "WARNING: 源 run 中缺少 SCB 配置 $src_scb_configs，跳过" >& /dev/stderr
  endif

  # 7.5 STA configs
  if ( -e "$src_run/$src_sta_configs" ) then
    if ( -d "$src_run/$src_sta_configs" ) then
      cp -rp "$src_run/$src_sta_configs" "$run_dir/"
      foreach cf ( `find "$run_dir/$src_sta_configs" -type f` )
        set copied_files = ( $copied_files $cf )
      end
    else
      cp -p "$src_run/$src_sta_configs" "$run_dir/"
      set copied_files = ( $copied_files "$run_dir/$src_sta_configs" )
    endif
  else
    echo "WARNING: 源 run 中缺少 STA 配置 $src_sta_configs，跳过" >& /dev/stderr
  endif

  # 7.6 [ASSUMPTION-F] 路径改写：源 run 绝对路径 -> 新 run 绝对路径（仅文本文件）。
  #     注：sed -i 依赖 GNU sed（RHEL/CentOS 等默认）；若路径含 | & \ 等特殊字符需调整定界符。
  foreach f ( $copied_files )
    if ( -f "$f" ) then
      sed -i "s|${src_abs}|${new_run_abs}|g" "$f"
    endif
  end
  echo "==> 已改写 $#copied_files 个配置中的路径: $src_abs -> $new_run_abs"
endif

#===============================================================================
# 8. 模式 3：DB 符号链接 + stage marker（REQ-007 / REQ-008）
#===============================================================================
set link_list   = ()
set marker_list = ()
if ( "$start_step" != "" ) then
  switch ( "$start_step" )
    case "preplace":
      set link_list   = ( "init.enc" "init.enc.dat" )
      set marker_list = ( "init" )
      breaksw
    case "place":
      set link_list   = ( "preplace.enc" "preplace.enc.dat" )
      set marker_list = ( "init" "preplace" )
      breaksw
    case "ccopt":
      set link_list   = ( "place_opt_design.enc" "place_opt_design.enc.dat" )
      set marker_list = ( "init" "preplace" "place" )
      breaksw
    case "route":
      set link_list   = ( "ccopt_opt.enc" "ccopt_opt.enc.dat" )
      set marker_list = ( "init" "preplace" "place" "ccopt" )
      breaksw
  endsw

  # 8.1 DB 符号链接（REQ-007：必须是 symlink、target 必须为绝对路径；RULE-1 成对）
  foreach db ( $link_list )
    set link_name   = "$run_dir/PR/DB/$db"
    set link_target = "${src_abs}/PR/DB/$db"
    if ( -e "$link_target" ) then
      ln -s "$link_target" "$link_name"
      echo "==> LINK: $link_name -> $link_target"
    else
      echo "WARNING: 源 run 缺少输入 DB: $link_target，跳过该链接" >& /dev/stderr
    endif
  end

  # 8.2 touch 前置步骤的 stage marker（RULE-3；[ASSUMPTION-E] MARKER_DIR 占位变量）
  if ( "$MARKER_DIR" != "" ) then
    mkdir -p "$run_dir/$MARKER_DIR"
    foreach mk ( $marker_list )
      touch "$run_dir/$MARKER_DIR/$mk"
      echo "==> MARKER: touch $run_dir/$MARKER_DIR/$mk"
    end
  else
    echo "WARNING [ASSUMPTION-E]: MARKER_DIR 未配置，未 touch 任何 marker" >& /dev/stderr
  endif
endif

#===============================================================================
# 9. 完成信息
#===============================================================================
echo ""
echo "=============================="
echo " 完成: $run_dir"
echo " 模式: $mode"
echo " block: $block"
if ( $use_f ) then
  echo " 源 run: $src_run ($src_abs)"
endif
if ( "$start_step" != "" ) then
  echo " start_step: $start_step"
endif
echo "=============================="
