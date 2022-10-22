# Interactive shell (REPL) for Dart

## Introduction

TODO

## Feature details

### Expressions

```
>>> a = 'Hello'; b = ' world!'; 
>>> '$a, $b'                   
Hello,  world!
```

### Statements

```
>>> print(a)
Hello
```

<small>(All methods, not only `print`)</small>

### Functions

#### Define and redefine

```
>>> String f() => 'old';
>>> f()
old
>>> String f() => 'new';
>>> f()
new
```

#### Use local and global variables

```
>>> a = 10;
>>> int f() { int b = 20; a++; b++; return a+b; }
>>> f() 
32
>>> f()
33
```

### Classes

#### Define and redefine, preserving states

```
>>> class C { int a = 10; int f() => a * 2; }
>>> c = C(); print(c.f());
20
>>> class C { int a = 1000; int f() => a * 3; }
>>> c.f()
30
```

<small>Remark: This follows the Dart hot reload semantics.</small>

#### Extends and implements

```
>>> class A { int f() => 10; } class B extends A { int f() => 20; }
>>> A().f() + B().f()
30
>>> class B implements A { int f() => 30; }
>>> A().f() + B().f()
40
```

#### Use local variables, fields, and global variables

```
>>> a = 10;
>>> class C { int b = 20; int f() { int c = 30; a++; b++; c++; return a+b+c; } }
>>> c = C(); print(c.f()); print(c.f());
63
65
```

### Download new libraries

Use `!dart pub add package_name`, just like what is done in Python (Jupyter/IPython).

```
>>> join('directory', 'file.txt')
(...error, since have not added that dependency...)
>>> !dart pub add path
Resolving dependencies...

+ path 1.8.2

Changed 1 dependency!

>>> join('directory', 'file.txt')
(...error, since have imported it...)
>>> import 'package:path/path.dart';
>>> join('directory', 'file.txt')   
directory/file.txt
```

### Imports

#### Built-in package

```
>>> Random().nextInt(100)
(some error outputs here, because it is not imported)
>>> import "dart:math";
>>> Random().nextInt(100)
9
```

#### Third party package

TODO

### Multiple in one go

```
>>> int g() => 42; class C { int a = 10; int f() => a * 2; }
>>> C().f() + g()
62
```

### Multi line if not ended

(The `...`, instead of `>>>`, appears in the two lines, because the package detects it is not finished.)

```
>>> class C {
...   int a = 10;
... }
>>> 
```

### Run commands

Use prefix `!`.

```
>>> !whoami
tom
>>> !date
2022-10-22 ...outputs...
```

