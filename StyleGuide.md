## Style Guide ##

### Spacing ###

The opening bracket of a function call _does not_ require a space: `blahFunc(2, 3)`

Casts _do not_ require a space.

Arguments _do_ require a space after the comma.

Mathematical and boolean operators _do_ require a space before and after them: `blahFunc(2 + 3, 4 * 5)` and `if (true && false)`


### Indentation ###

Indentation is done with 2 spaces.

Wrong:
```
void someFunc() {
    if (true)
        writefln("This is wrong");
}
```

Right:
```
void someFunc() {
  if (true)
    writefln("This is right");
```

### Braces and Opening Blocks ###

Braces are on the same level as the block that they open.

Wrong:
```
void someFunc()
{
  while (1)
  {
    writefln("Wrong!");
  }
}
```

Right:
```
void someFunc() {
  while (1) {
    writefln("Right");
  }
}
```

### Classes ###

Class names are in camel-caps. The 1st letter is always upper-case.

Wrong:
```
class myClass { ... }
class another_wrong_class_name { ... }
class Myclassnameis wrong { ... }
```

Right:
```
class MyClass { ... }
class AnotherWrongClassName { ... }
class MyClassNameIsRight { ... }
```

Class methods are in camel-caps. The 1st letter is always lower-case.

Wrong:
```
class MyClass {
  void DoStuff() { ... };
  void do_more_stuff() { ... };
}
```

Right:
```
class MyClass {
  void doStuff() { ... };
  void doMoreStuff() { ... };
```

### Functions ###

Function names are in camel-caps. The 1st letter is always lower-case.

### Everything else ###

All other dirty tricks are acceptable. If the trick is really dirty, document it with comments to explain _why_ (and maybe _how_) it works.