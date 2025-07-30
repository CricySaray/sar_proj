# 数据映射器 - 提供双向映射和唯一ID分配功能
package provide DataMapper 1.0

namespace eval ::DataMapper {
  variable nextId 1
  variable idToValuesMap {}
  variable valueToIdMaps {}
}

# 创建新的数据映射器实例
proc ::DataMapper::create {} {
  set obj [namespace current]::[incr ::DataMapper::nextId]
  namespace eval $obj {
    variable nextId 1
    variable idToValuesMap {}
    variable valueToIdMaps {}
  }
  return $obj
}

# 添加映射 - 接受多个值，返回唯一ID
proc ::DataMapper::add {obj args} {
  upvar #0 $obj nextId idToValuesMap valueToIdMaps

  if {[llength $args] < 2} {
    error "至少需要两个值来创建映射"
  }

  set id [incr nextId]
  lappend idToValuesMap $id $args

  # 为每个值创建反向映射到ID
  foreach value $args {
    if {![info exists valueToIdMaps($value)]} {
      set valueToIdMaps($value) $id
    } else {
      error "值 '$value' 已存在于映射中，ID为 $valueToIdMaps($value)"
    }
  }

  return $id
}

# 通过ID获取映射的值
proc ::DataMapper::getById {obj id} {
  upvar #1 $obj idToValuesMap

  if {[dict exists idToValuesMap $id]} {
    return [dict get $idToValuesMap $id]
  } else {
    error "ID '$id' 不存在"
  }
}

# 通过任意值获取ID
proc ::DataMapper::getId {obj value} {
  upvar #0 $obj valueToIdMaps

  if {[info exists valueToIdMaps($value)]} {
    return $valueToIdMaps($value)
  } else {
    error "值 '$value' 不存在于映射中"
  }
}

# 通过任意值获取所有映射的值
proc ::DataMapper::get {obj value} {
  return [getById $obj [getId $obj $value]]
}

# 检查ID是否存在
proc ::DataMapper::idExists {obj id} {
  upvar #0 $obj idToValuesMap
  return [dict exists $idToValuesMap $id]
}

# 检查值是否存在于任何映射中
proc ::DataMapper::valueExists {obj value} {
  upvar #0 $obj valueToIdMaps
  return [info exists valueToIdMaps($value)]
}

# 删除映射
proc ::DataMapper::remove {obj id} {
  upvar #0 $obj idToValuesMap valueToIdMaps

  if {![idExists $obj $id]} {
    error "ID '$id' 不存在"
  }

  set values [dict get $idToValuesMap $id]
  dict unset idToValuesMap $id

  # 清理值到ID的映射
  foreach value $values {
    if {[info exists valueToIdMaps($value)] && $valueToIdMaps($value) == $id} {
      unset valueToIdMaps($value)
    }
  }

  return $id
}

# 获取所有ID
proc ::DataMapper::getAllIds {obj} {
  upvar #0 $obj idToValuesMap
  return [dict keys $idToValuesMap]
}

# 获取所有值
proc ::DataMapper::getAllValues {obj} {
  upvar #0 $obj valueToIdMaps
  return [array names valueToIdMaps]
}

# 获取映射数量
proc ::DataMapper::size {obj} {
  upvar #0 $obj idToValuesMap
  return [dict size $idToValuesMap]
}

# 清空所有映射
proc ::DataMapper::clear {obj} {
  upvar #0 $obj nextId idToValuesMap valueToIdMaps

  set nextId 1
  array unset valueToIdMaps
  dict unset idToValuesMap
}

# 示例使用
if {$::argv0 eq [info script]} {
  set mapper [::DataMapper::create]

  # 添加映射
  set id1 [::DataMapper::add $mapper "apple" "fruit" "red"]
  puts "添加映射，ID: $id1"

  set id2 [::DataMapper::add $mapper "carrot" "vegetable" "orange"]
  puts "添加映射，ID: $id2"

  # 通过ID获取映射
  puts "ID $id1 对应的映射: [::DataMapper::getById $mapper $id1]"

  # 通过值获取ID
  puts "值 'apple' 对应的ID: [::DataMapper::getId $mapper "apple"]"

  # 通过值获取所有映射的值
  puts "与 'vegetable' 关联的值: [::DataMapper::get $mapper "vegetable"]"

  # 检查存在性
  puts "ID $id2 是否存在: [::DataMapper::idExists $mapper $id2]"
  puts "值 'red' 是否存在: [::DataMapper::valueExists $mapper "red"]"

  # 获取所有ID和值
  puts "所有ID: [::DataMapper::getAllIds $mapper]"
  puts "所有值: [::DataMapper::getAllValues $mapper]"

  # 删除映射
  ::DataMapper::remove $mapper $id1
  puts "删除ID $id1 后，剩余映射数量: [::DataMapper::size $mapper]"

  # 清空映射器
  ::DataMapper::clear $mapper
  puts "清空后，映射数量: [::DataMapper::size $mapper]"
}    
