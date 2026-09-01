# Python 教程速查表（廖雪峰 · 第1~17章）

来源：《Python教程》（廖雪峰）前 17 章内容整理，作为日常查阅用的 cheatsheet。重点章节保留经典代码示例。

## 1. 简介
- Python 是解释型高级语言，代码简洁、生态丰富（AI/数据分析/Web/自动化）。
- 本章为总览，无具体语法。

## 2. Python 历史
- 由 Guido van Rossum 于 1991 年发布，强调代码可读性。
- Python 3 是当前主版本（不兼容 Python 2）。

## 3. 安装 Python
- 官网下载安装；Windows 安装时务必勾选 **Add python.exe to PATH**（否则命令找不到，可重装或手动加环境变量）。
- 验证：Windows 打开 PowerShell 运行 `python`，Mac/Linux 运行 `python3`；看到 `>>>` 即进入交互环境，`exit()` 退出。
- 常用解释器：**CPython**（官方默认，最常用）、IPython（交互增强）、PyPy（JIT 加速）、Jython（Java 平台）、IronPython（.NET 平台）；教程均基于 CPython 3.x。
- 推荐安装 Anaconda（内置大量科学计算/第三方库），可避免逐个 pip 安装。

## 4. 第一个 Python 程序
- 两种运行方式：**交互式命令行**（`>>>` 逐行执行，适合调试/学习）与 **.py 脚本文件**（`python hello.py` 一次性执行；交互模式会自动打印结果，脚本需显式 `print`）。
- 输出：`print('a', 'b')` 逗号分隔会输出一个空格；`print('100 + 200 =', 100+200)` 打印计算结果。
- 输入：`name = input('please enter your name: ')` 提示并读取；**input() 返回 str**。
- 注释：`#` 单行；`'''...'''` 多行。文件须以 `.py` 结尾，文件名用字母/数字/下划线。
- 常见报错：`SyntaxError` 多为中文标点（如中文括号 `（）`/引号）；`python: can't open file` 表示当前目录没有该文件，先用 `cd` 切到文件所在目录。

## 5. Python 基础
### 数据类型和变量
- 代码块用**缩进**组织（冒号 `:` 结尾 + 缩进），始终用 **4 个空格**，不要混用 Tab。
- 整数 `int`（无大小限制）、浮点数 `float`（超出范围显示 `inf`）、字符串 `str`、布尔 `bool`（True/False）、空值 `None`（不是 0）。
- 除法：`/` 结果为浮点数、`//` 地板除、`%` 取余；整数运算结果精确，浮点有四舍五入误差。
- 动态语言：变量无需声明类型；赋值 `x = y` 是让 x 指向 y 所指向的对象，之后改 y 不影响 x。
- 常量约定全大写命名（如 `PI`），只是约定，实际可改。

### 字符串和编码
- 字符串：单/双引号均可，`'I\'m "OK"!'` 用 `\` 转义；`r'...'` 不转义；`'''...'''` 多行。
- 编码：ASCII（1 字节）→ Unicode（内存中统一）→ UTF-8（存储/传输，英文 1 字节、汉字 3 字节）。
- `ord('A')` 取码点，`chr(66)` 转字符；`'\u4e2d\u6587'` 十六进制写法。
- 编码转换：`'中文'.encode('utf-8')` → bytes；`b'...'.decode('utf-8')` → str（加 `errors='ignore'` 忽略坏字节）。
- `len('中文')` 数字符数=2；`len('中文'.encode('utf-8'))` 数字节数=6。
- 源文件含中文时开头写 `# -*- coding: utf-8 -*-` 并确保编辑器用 UTF-8 保存。
- 格式化：`%` 占位符（`%s`/`%d`/`%f`/`%x`，`'%2d-%02d'` 补零、`'%.2f'` 小数位、`%%` 表示 `%`）；`'Hi, {0}, 成绩提升了 {1:.1f}%'.format(name, n)`；最新 **f-string** `f'The area is {s:.2f}'`。

### list 和 tuple
- `list` 可变：`len()`、`append()`、`insert(i, x)`、`pop()`/`pop(i)`、`L[i] = x` 替换、索引 `-1` 倒数；元素类型可不同、可嵌套。
- `tuple` 不可变（更安全，能用的地方尽量用）：`(1, 2, 3)`；单元素须写 `(1,)`；`t = ('a', 'b', ['X', 'Y'])` 内层 list 可变（tuple“指向不变”）。

### 条件判断
```python
if age >= 18:
    print('adult')
elif age >= 6:
    print('teenager')
else:
    print('kid')
```
- 自上而下匹配，命中后跳过其余 elif/else；注意冒号；`if x:` 中非零数值、非空字符串/list 为真。
- `input()` 返回 **str**，与整数比较前要先 `int(s)` 转换。

### 模式匹配（match，Python 3.10+）
```python
match score:
    case 'A': print('score is A.')
    case 'B': print('score is B.')
    case _:   print('score is ???.')     # _ 匹配任意值，只能放最后

match age:                                # 可匹配范围/多值并绑定变量
    case x if x < 10: print(f'< 10 years old: {x}')
    case 10: print('10 years old.')
    case 11 | 12 | 13: print('11~13 years old.')
    case _: print('not sure.')

match ['gcc', 'hello.c']:                 # 可匹配列表结构
    case ['gcc']: print('gcc: missing source file(s).')
    case ['gcc', file1, *files]: print('gcc compile: ' + file1 + ', ' + ', '.join(files))
    case ['clean']: print('clean')
    case _: print('invalid command.')
```

### 循环
- `for x in iterable` 遍历；`while 条件` 循环；`break` 跳出整个循环；`continue` 跳过本轮；`range(n)` 生成 0~n-1。
- 不要滥用 break/continue；死循环用 `Ctrl+C` 中断。

### dict 和 set
- `dict` 哈希表，查找极快（空间换时间）：`d = {'Michael': 95}`；`d['key']` 取值（不存在报 KeyError）；`'key' in d` 判断；`d.get('key', 默认)` 安全取值；`d.pop(key)` 删除；多次赋同 key 后值覆盖。
- `set` 无序不重复：`s = {1, 2, 3}` 或 `set([1,2,3])`；`add()`、`remove()`；交集 `&`、并集 `|`。
- dict/set 的 key 必须是不可变对象（str、int、tuple 可；list 不可，报 `TypeError: unhashable type`）。
- 不可变对象：调用其方法不会改变自身，而是创建新对象返回（如 `a.replace('a','A')` 后 a 不变）。

## 6. 函数
### 定义与调用
```python
def my_abs(x):
    if not isinstance(x, (int, float)):   # 参数类型检查
        raise TypeError('bad operand type')
    if x >= 0:
        return x
    return -x
```
- 无 return 时返回 `None`；`return None` 可简写为 `return`。
- 函数可返回多个值，实际是返回一个 tuple：`return nx, ny`。

### 函数的参数（按定义顺序：必选、默认、可变、命名关键字、关键字）
```python
def f1(a, b, c=0, *args, **kw):          # 可变参数 *args 收 tuple
    pass
def f2(a, b, c=0, *, d, **kw):           # 命名关键字 * 后 d 必须按名传入
    pass
```
- **默认参数必须指向不可变对象**：`def add_end(L=None): if L is None: L = []`，切勿用 `L=[]`（会被多次调用累计污染）。
- 调用时拆包：`func(*list)`、`func(**dict)`；任意函数都可 `func(*args, **kw)` 调用。
- `*args` 是可变参数（tuple），`**kw` 是关键字参数（dict）。

### 递归函数
```python
def fact(n):
    if n == 1:
        return 1
    return n * fact(n - 1)
```
- 递归过深会栈溢出（`RecursionError`）；尾递归 `fact_iter(num-1, num*product)` 可避免栈增长，但 **Python 解释器未做尾递归优化**。

## 7. 高级特性
### 切片
```python
L[0:3]        # 取索引0~2，等价 L[:3]
L[-2:]        # 倒数两个
L[::2]        # 步长为2
L[:]          # 原样复制
'ABCDEFG'[::2] # 字符串也可切片 → 'ACEG'
```

### 迭代
- 任何可迭代对象都可 `for` 遍历；dict 默认迭代 key，`d.values()` 迭代值，`d.items()` 迭代键值对。
- `for i, value in enumerate(['A','B'])` 同时取索引与元素。

### 列表生成式
```python
[x * x for x in range(1, 11)]              # [1,4,9,...,100]
[x * x for x in range(10) if x % 2 == 0]   # for 后的 if 是过滤，不能带 else
[x if x % 2 == 0 else -x for x in range(10)] # for 前的 if...else 是表达式
[m + n for m in 'ABC' for n in 'XYZ']      # 两层循环生成全排列
```

### 生成器 generator
- 列表生成式的 `[]` 改 `()` 即生成器：`g = (x * x for x in range(10))`。
- 函数含 `yield` 即为生成器函数，调用返回 generator 对象；用 `for` 遍历，`next(g)` 逐个取（耗尽抛 StopIteration）。
```python
def fib(max):
    n, a, b = 0, 0, 1
    while n < max:
        yield b
        a, b = b, a + b
```
- 生成器的 `return` 返回值只能通过捕获 `StopIteration.value` 取得。

### 迭代器
- 可作用于 `for` 的是 `Iterable`；可被 `next()` 调用的是 `Iterator`（惰性计算）。
- `list/dict/str` 是 Iterable 但不是 Iterator，用 `iter()` 转换；生成器都是 Iterator。
- `for` 循环本质就是不断 `next(it)` 直到 StopIteration。

## 8. 函数式编程
- Python 部分支持函数式：函数可作为参数传入、也可作为返回值。

### 高阶函数 map / reduce / filter / sorted
```python
list(map(str, [1, 2, 3]))                 # map 将函数作用到每个元素 → ['1','2','3']
from functools import reduce
reduce(lambda x, y: x * 10 + y, [1,3,5,7,9])  # 累积计算 → 13579
list(filter(is_odd, [1,2,4,5,6,9,10,15])) # filter 按 True/False 筛元素（返回 Iterator）
sorted([36, 5, -12, 9, -21], key=abs)     # key 指定排序规则
sorted(['bob','about','Zoo','Credit'], key=str.lower, reverse=True)
```

### 返回函数 / 闭包
```python
def lazy_sum(*args):
    def sum():
        ax = 0
        for n in args:          # 内部函数引用外部参数 args → 闭包
            ax = ax + n
        return ax
    return sum                  # 返回的是函数，调用 f() 才真正求和
```
- **返回闭包时不要引用循环变量**；若必须引用，用额外参数绑定当前值 `def f(j): def g(): return j*j; return g`，即 `f(i)`。
- 内层函数需对外层变量赋值时用 `nonlocal x`。

### 匿名函数
```python
list(map(lambda x: x * x, [1, 2, 3]))
f = lambda x: x * x          # 只能写一个表达式，无 return
```

### 装饰器
```python
import functools
def log(func):
    @functools.wraps(func)      # 保留原函数 __name__ 等属性
    def wrapper(*args, **kw):
        print('call %s():' % func.__name__)
        return func(*args, **kw)
    return wrapper

@log
def now(): print('2024-6-1')
```
- 带参数的装饰器需 3 层嵌套：`@log('execute')` → `now = log('execute')(now)`。

### 偏函数
```python
import functools
int2 = functools.partial(int, base=2)   # 固定部分参数生成新函数
int2('1000000')  # 64
max2 = functools.partial(max, 10)       # 10 会作为 *args 加到最前面
```

## 9. 模块
- 一个 `.py` 文件即一个模块；目录下含 `__init__.py` 即包（`__init__.py` 也可为空或有代码）。
- 模块名避免与系统模块冲突；`import` 后可用 `模块名.函数名` 访问。
- 标准文件模板：首行 `#!/usr/bin/env python3`、编码声明 `# -*- coding: utf-8 -*-`、文档字符串、`__author__`。
- `if __name__ == '__main__':` 使模块被直接运行时执行测试代码，被 import 时不执行。
- 作用域：普通名公开；`_xxx`/`__xxx` 视为 private（只是约定，无强制）；`__xxx__` 是特殊变量。
- 安装第三方库：`pip install 包名`（Mac/Linux 可能是 `pip3`）；可用 Anaconda 批量内置。
- 模块搜索路径：`sys.path`，可 `sys.path.append('目录')`（运行时有效）或设环境变量 `PYTHONPATH`。

## 10. 面向对象编程
### 类和实例
```python
class Student(object):
    def __init__(self, name, score):   # 第一个参数永远是 self
        self.name = name
        self.score = score
    def get_grade(self):
        if self.score >= 90: return 'A'
        elif self.score >= 60: return 'B'
        return 'C'
bart = Student('Bart Simpson', 59)
bart.print_score()
```
- 类方法第一个参数是 self（调用时不传）；实例可自由绑定任意属性（动态语言特性）。

### 访问限制
- `self.__name` 双下划线开头为私有变量，外部不能直接访问。
- 提供 `get_name()`/`set_score(value)` 方法访问/修改；setter 内可做参数校验（如 `0 <= score <= 100` 否则 `raise ValueError`）。
- `__xxx__` 是特殊变量可访问；`_xxx` 单下划线是“请视为私有”的约定。
- 双下划线实际被改名 `_Student__name`（仍可绕过，但不建议）。

### 继承和多态
```python
class Animal(object):
    def run(self): print('Animal is running...')
class Dog(Animal):
    def run(self): print('Dog is running...')   # 覆盖父类方法
def run_twice(animal):
    animal.run()
    animal.run()
```
- 子类自动获得父类全部方法，可覆盖重写 → 多态。
- `isinstance(c, Dog)` 与 `isinstance(c, Animal)` 均为 True（子类也是父类类型）；父类实例不是子类。
- “开闭原则”：对扩展开放（可新增子类），对修改封闭（调用方无需改动）。
- 动态语言“鸭子类型”：不要求继承，只要有 `run()` 方法即可，如 `file-like object`（有 `read()` 即可）。

### 获取对象信息
- `type(x)` 返回类型；`isinstance(x, (list, tuple))` 判断类型（含继承链，优先用）；`dir(obj)` 列出属性和方法。
- `hasattr(obj, 'x')`、`getattr(obj, 'x', 默认)`、`setattr(obj, 'x', v)` 操作属性。
- 自定义类实现 `__len__()` 后可用 `len(obj)`。

### 实例属性和类属性
- 实例属性属于各实例互不影响；类属性（class 内直接定义）所有实例共享。
- **不要给实例属性和类属性起相同名字**，实例属性会屏蔽类属性（删除实例属性后回到类属性）。

## 11. 面向对象高级编程
### __slots__ 限制属性
```python
class Student(object):
    __slots__ = ('name', 'age')   # 只允许绑定这两个属性，否则 AttributeError
```
- `__slots__` 只对当前类实例生效；子类需自己再定义（结果为子类+父类之和）。

### @property
```python
class Student(object):
    @property
    def score(self):
        return self._score
    @score.setter
    def score(self, value):
        if not isinstance(value, int): raise ValueError('must be int')
        if value < 0 or value > 100: raise ValueError('0~100')
        self._score = value
```
- 调用时像普通属性：`s.score = 60`；只定义 getter（无 setter）即为只读属性。
- **属性方法名不能与内部变量重名**（如 `def score(self): return self.score` 会无限递归栈溢出），应把值存到 `self._score`。

### 多重继承 / MixIn
```python
class RunnableMixIn(object):
    def run(self): print('Running...')
class Dog(Mammal, RunnableMixIn):
    pass
```
- 一个子类可同时获得多个父类功能；MixIn 用于组合式增加功能（如 `TCPServer + ForkingMixIn`）。

### 定制类（常用魔术方法）
- `__str__` / `__repr__`：`print()` 与交互显示（`__repr__ = __str__` 偷懒写法）。
- `__iter__` + `__next__`：让实例可 `for` 遍历。
- `__getitem__`：让实例支持 `obj[n]` 下标/切片（参数可能是 int 或 slice）。
- `__getattr__(self, attr)`：属性不存在时动态返回（未找到才调用）；不认识的属性应 `raise AttributeError`；可做链式调用（如 REST API SDK：`Chain().status.user.timeline.list`）。
- `__call__`：实例可直接调用 `obj()`；`callable(obj)` 判断是否可调用。

### 枚举类
```python
from enum import Enum, unique
@unique                          # 检查保证没有重复值
class Weekday(Enum):
    Sun = 0; Mon = 1; Tue = 2
Weekday.Mon          # 成员
Weekday['Tue']       # 按名字取
Weekday(1)           # 按 value 取，非法值抛 ValueError
```

### 元类（metaclass，了解即可）
- 类本身也是 `type` 的实例；可用 `type('Hello', (object,), dict(hello=fn))` 动态创建类。
- metaclass 是创建类的“模板”：继承 `type`，重写 `__new__(cls, name, bases, attrs)`，类定义时传 `metaclass=xxx` 即可修改类（典型应用：ORM 框架，如 `ModelMetaclass` 把 `Field` 属性收集到 `__mappings__` 并生成 `__table__`，`Model.save()` 拼出 INSERT SQL）。

## 12. 错误、调试和测试
### 错误处理
```python
try:
    r = 10 / int('0')
except ValueError as e:
    print('ValueError:', e)
except ZeroDivisionError as e:
    print('ZeroDivisionError:', e)
else:
    print('no error')
finally:
    print('finally...')   # 无论是否出错都会执行
```
- 捕获到错误后可 `logging.exception(e)` 记录，或 `raise` 原样抛出；`raise MyError('...')` 抛出自定义错误（继承 `Exception`）。
- 用 `logging`（`import logging; logging.basicConfig(level=logging.INFO)`）记录比 print 更好。

### 调试
- 断言：`assert n != 0, 'n is zero!'`（`python -O` 可关闭）。
- `logging` 分级别 DEBUG/INFO/WARNING/ERROR。
- `pdb` 调试器：`python -m pdb script.py`，`n` 单步、`p 变量`、`q` 退出；或代码里 `pdb.set_trace()` 断点。

### 单元测试（unittest）
```python
import unittest
class TestDict(unittest.TestCase):
    def test_init(self):
        d = Dict(a=1)
        self.assertEqual(d.a, 1)
    def setUp(self):    # 每个测试前执行
        pass
    def tearDown(self): # 每个测试后执行
        pass
if __name__ == '__main__':
    unittest.main()
```
- 常用断言：`assertEqual/assertTrue/assertFalse/assertRaises`；运行 `python -m unittest 文件名`。

### 文档测试（doctest）
- 在函数 docstring 里写 `>>>` 交互示例，`doctest.testmod()` 自动验证输出。

## 13. IO 编程
### 文件读写
```python
with open('/path/file.txt', 'r', encoding='utf-8') as f:
    print(f.read())          # 一次性读全文；f.readlines() 按行
with open('/path/file.txt', 'w', encoding='utf-8') as f:
    f.write('hello')
```
- 模式：`r` 读、`w` 写（覆盖）、`a` 追加、`rb/wb` 二进制（bytes）；`with` 自动关闭文件。
- 读二进制/未知编码时可能报 UnicodeDecodeError，可加 `errors='ignore'`。

### StringIO / BytesIO（内存中的文件）
- `StringIO()` 在内存读写字符串：`getvalue()` 取内容。
- `BytesIO()` 在内存读写 bytes。

### 操作文件和目录（os / os.path）
- `os.name`、`os.environ`；`os.path.abspath('.')`、`os.path.join('/a','b')`、`os.path.split()`、`os.path.splitext()`（取扩展名）。
- `os.mkdir()`、`os.rmdir()`、`os.rename()`、`os.remove()`。
- `os.listdir('.')` 列出目录；`shutil` 模块可复制文件。

### 序列化
- `pickle`：`pickle.dumps(obj)`/`pickle.loads()`（二进制，仅 Python 用）。
- `json`：`json.dumps(obj)`/`json.loads()`；`json.dump(obj, f)`/`json.load(f)` 读写文件；`ensure_ascii=False` 保留中文。
- 对象序列化：定义转换函数 `student2dict(std)` 传给 `json.dumps(..., default=student2dict)`，反序列化用 `object_hook`。
- 可加 `sort_keys=True` 按 key 排序输出。

## 14. 进程和线程
### 多进程
- Unix/Linux `os.fork()` 复制进程（Windows 不支持）。
- `multiprocessing`：`Process(target=fn, args=(...))`，`p.start()`、`p.join()`；`Pool` 进程池 `p.map`。
- 进程间通信：`multiprocessing.Queue`、`Pipe`。
- 子进程：`subprocess` 模块调用外部命令。

### 多线程
```python
import threading
t = threading.Thread(target=fn, args=())
t.start(); t.join()
```
- 同一进程内线程共享全局变量 → 多线程改共享数据要加锁：
```python
lock = threading.Lock()
lock.acquire()
try:
    # 修改共享变量
finally:
    lock.release()
```
- Python 多线程受 GIL 限制，CPU 密集任务多线程不加速，IO 密集任务适用。

### ThreadLocal
- `local = threading.local()`；各线程可设置/读取自己的 `local.x`，互不干扰，避免传参。

### 进程 vs 线程
- 计算密集型 → 用多进程（可并行利用多核）；IO 密集型 → 多线程/异步更合适。
- 进程切换开销大、通信复杂；线程共享内存、切换快但需加锁。

### 分布式进程
- `multiprocessing.managers`：把 `Queue` 注册到网络（`BaseManager` + `register` + `get_manager`），实现多台机器上的进程协作（生产者/消费者模型）。

## 15. 正则表达式
- 元字符：`\d` 数字、`\w` 字母数字下划线、`\s` 空白、`.` 任意字符、`*`/`+`/`?` 量词、`{n,m}` 次数、`[]` 字符集、`^`/`$` 开头结尾、`|` 或、`()` 分组。
- Python 字符串中 `\` 需转义，建议写原始字符串 `r'...'`。
```python
import re
re.match(r'^\d{3}\-\d{3,8}$', '010-12345')   # 匹配开头，返回 Match 或 None
re.split(r'[\s\,]+', 'a, b,  c')              # 切分字符串
m = re.match(r'^(\d{3})-(\d{3,8})$', '010-12345')
m.group(0)  # '010-12345'; m.group(1) '010'; m.group(2) '12345'
re.compile(r'...')                            # 预编译正则提高效率
```
- 贪婪匹配：默认尽可能多匹配，`*?`/`+?` 改为非贪婪。

## 16. 常用内建模块
### datetime
- `datetime.now()` 当前时间；`datetime(2015,4,19,12,20)` 指定时间；`dt.timestamp()` 转 epoch 秒；`datetime.fromtimestamp(t)` 转回本地时间。
- 字符串与时间互转：`datetime.strptime(s, '%Y-%m-%d %H:%M:%S')`、`dt.strftime('%a, %b %d %H:%M')`。
- 加减：`now + timedelta(hours=10, days=1)`。
- 时区：`timezone(timedelta(hours=8))` 设本地时区；`dt.astimezone(tz)` 转换时区。

### collections
- `namedtuple('Point', ['x','y'])`：带名字的 tuple，可用 `p.x` 访问且仍是 tuple。
- `deque`：双向队列，`appendleft/popleft` 高效头尾操作。
- `defaultdict(lambda: 'N/A')`：key 不存在时返回默认值。
- `OrderedDict`：保持插入顺序的 dict（可做 FIFO 队列，如 LRU）。
- `ChainMap`：把多个 dict 合并为“链式查找”，前面优先（常用于默认参数+环境变量+命令行）。
- `Counter`：计数统计，`Counter('programming')`。

### argparse（命令行参数解析）
```python
import argparse
parser = argparse.ArgumentParser(prog='backup', description='Backup MySQL database.')
parser.add_argument('outfile')                      # 位置参数
parser.add_argument('--host', default='localhost')  # 关键字参数
parser.add_argument('-u', '--user', required=True)  # 必填 + 简写
args = parser.parse_args()
# 自动支持 -h 帮助、错误提示
```

### base64
- 用 64 个字符表示任意二进制：`base64.b64encode(b'...')` / `b64decode`；URL 安全版 `urlsafe_b64encode`。
- 编码后常自动去掉 `=`，解码时需补回（`s + '=' * (-len(s) % 4)`）。

### struct（二进制打包）
- `struct.pack('>I', 10240099)` 按指令打包；`struct.unpack('>IH', b'...')` 解包。
- 常用格式：`>I` 大端无符号 int、`<H` 小端无符号 short；可解析文件头（如 BMP 图像宽高/色深）。

### hashlib（哈希/摘要）
```python
import hashlib
md5 = hashlib.md5(); md5.update('how to use md5'.encode('utf-8')); md5.hexdigest()
sha1 = hashlib.sha1(); sha1.update(b'...'); sha1.hexdigest()
```
- 单向不可逆；用于校验与口令存储。防“彩虹表”需加盐（salt）：`calc_md5(password + salt)`，每个用户随机 salt。

### hmac（加 key 的哈希）
```python
import hmac
h = hmac.new(b'secret', b'...', 'MD5'); h.hexdigest()
```
- 把 key 混入哈希过程，比单纯加盐更安全；验证需同时提供正确 key。

### itertools（迭代器工具）
- 无限迭代器：`count(n)` 从 n 递增、`cycle('ABC')` 循环、`repeat('A', 3)` 重复。
- 组合/分组：`chain()` 串联、`groupby()` 按 key 分组（需先排序）、`takewhile()` 截取满足条件的有限序列。

### contextlib（上下文管理）
- 自定义类实现 `__enter__/__exit__` 即可用于 `with`。
- 更简单：`@contextmanager` 装饰器 + `yield`：
```python
from contextlib import contextmanager
@contextmanager
def tag(name):
    print('<%s>' % name); yield; print('</%s>' % name)
with tag('h1'): print('hello')
```
- `@contextlib.closing(obj)`：自动调用 `close()`（如 `urlopen` 结果）。

### urllib（网络请求）
```python
from urllib import request
with request.urlopen('https://api.douban.com/v2/book/2129650') as f:
    data = f.read(); print(f.status, f.getheaders())
```
- 可带 `Request(url, data, headers={'User-Agent': '...'})` 模拟浏览器；POST 用 `data=urllib.parse.urlencode({...}).encode('utf-8')`。

### XML
- 解析：优先 SAX（`xml.parsers.expat.ParserCreate`，实现 `start_element/end_element/char_data` 回调），DOM 太占内存。
- 生成：简单场景直接拼字符串。

### HTMLParser
- `from html.parser import HTMLParser`，继承并实现 `handle_starttag/handle_endtag/handle_data/handle_comment/handle_entityref` 等回调，`parser.feed(html)` 解析。

### venv（虚拟环境）
```bash
python3 -m venv .          # 创建独立环境（Mac/Linux 生成 bin/，Windows 生成 Scripts/）
source bin/activate        # 进入环境（Windows: .\Scripts\activate）
deactivate                 # 退出
```
- 为每个项目创建隔离的第三方包环境，互不干扰。

## 17. 常用第三方模块
### Pillow（图像处理）
- PIL 的活跃分支，支持 Python 3：`from PIL import Image`。
- 缩放：`img.thumbnail((w,h))`；模糊：`ImageFilter.BLUR`；旋转；格式转换 `img.save('x.png')`。
- 可生成字母验证码图片（`ImageDraw` 画文字/干扰线）。

### requests（HTTP 请求）
```python
import requests
r = requests.get('https://www.douban.com/', params={'q': 'python'})
r.status_code; r.text; r.json()          # 比 urllib 简洁得多
requests.post(url, data={'k': 'v'}, headers={...})
```

### chardet（编码检测）
```python
import chardet
chardet.detect(b'...')   # 返回 {'encoding': 'utf-8', 'confidence': ...}
```
- 读取未知编码文件前先检测编码。

### psutil（系统信息）
- 获取 CPU、内存、磁盘、网络、进程等系统信息：`psutil.cpu_percent()`、`psutil.virtual_memory()`、`psutil.disk_usage('/')`、`psutil.Process(pid)` 等。

---
*整理自《Python教程》（廖雪峰）第 1~17 章，供快速查阅。*
