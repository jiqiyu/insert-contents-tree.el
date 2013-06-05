insert-contents-tree.el
======================

Generate a contents tree according to given string.

Usage:
------------------------

Put the file into an auto load path, and `(require 'insert-contents-tree)`

For the sake of convenience, this func would expect an argument in the same format as in the `mkdir -p` command.<br>
For example `M-x insert-contents-tree <RET>` and then enter belowing string:
```
CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}
```
would insert following contents tree into current buffer(at the cursor point):

```

CONTENTS TITLE/
|-- 1
|   `-- 1.1
|       |-- 1.1.1
|       |   |-- 1.1.1.1
|       |   |-- 1.1.1.2
|       |   `-- 1.1.1.3
|       |-- 1.1.2
|       `-- 1.1.3
|-- 2
|   `-- 2.1
`-- 3
    `-- 3.1

```

If you change ```(JOINT '("|-- " "`-- "))``` to ```(JOINT '("├─" "└─"))``` and ```(VBSP "|   ")``` to ```(VBSP "│  ")```
in the .el file, the results would look like this:

```

CONTENTS TITLE/
├─1
│  └─1.1
│      ├─1.1.1
│      │  ├─1.1.1.1
│      │  ├─1.1.1.2
│      │  └─1.1.1.3
│      ├─1.1.2
│      └─1.1.3
├─2
│  └─2.1
└─3
   └─3.1

```  

Examples
---------------------

After require the func, you can check out following examples,

### A few examples of acceptable aurgument:

```el
(insert-contents-tree "Tree/{a,b,c}")
(insert-contents-tree "Tree/a/b/c")
(insert-contents-tree "Tree/{a/aa,b,c}")
(insert-contents-tree "Tree/{a,b/bb,c/cc/ccc,d/dd/ddd/dddd,e,f,g}")
(insert-contents-tree "Tree/{a/aa,b/bb,e/f,m/n/o/p/q/{r,s,t/u/v/w}}")
(insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}")
(insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3,1.1.4},2/{8,8}}")
(insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1/{a,b/{c,d/{e,f/{k,o}}},r},1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}")
(insert-contents-tree "TITLE/{1/2/{3/{4/{a,b/{c,d/{e,f/{k,o/b/b/b/b/{l,m,n,o/p}}}},r},5,6/{7,8,9,10/11/{12,13}}},14,15},2/2.1,3/3.1}")
```

### A few examples of illegal argument:

```el
;; if any one of "{/" "{}" "{," ",/" ",}" ",{" "/," "/}" "}/" "}{" "{{" "//" ",," occurs in string
;; signal an error: Wrong format of argument
(insert-contents-tree "tree/a/d/e//f")

;; if string ends with "," or "{" or "/"
;; signal an error: Wrong format of argument
(insert-contents-tree "tree/a/d/e/f,")

;; if braces do not match
;; signal an error: Wrong format of argument, braces do not match, unclosed {s
(insert-contents-tree "tree/{a/d/e/f,b/{g,c}")
;; signal an error: Wrong format of argument, unmatched braces, maybe too many }s
(insert-contents-tree "tree/{a/d/e/f,b/g,c}}")

;; other
;; signal an error: Wrong format of argument
(insert-contents-tree "tree/{a,b,c},d")
```
