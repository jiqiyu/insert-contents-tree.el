;;; insert-contents-tree.el --- Generate a contents tree according to given str

;; Copyright (C) 2013 Fog
     
;; Author: Fog
;; Created: 4 Jun 2013
;; Keywords: contents tree

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Put the file into an auto load path, and (require 'insert-contents-tree)

;; For the sake of convenience, this func would expect an
;; argument in the same format as in the `mkdir -p' command.
;; For example M-x insert-contents-tree <RET> and then enter
;; belowing string:
;; CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}
;; would insert following contents tree into current buffer(at the cursor point):

;; CONTENTS TITLE/
;; ├─1
;; │  └─1.1
;; │      ├─1.1.1
;; │      │  ├─1.1.1.1
;; │      │  ├─1.1.1.2
;; │      │  └─1.1.1.3
;; │      ├─1.1.2
;; │      └─1.1.3
;; ├─2
;; │  └─2.1
;; └─3
;;    └─3.1

;; after require the func, you can check out following examples, use C-x C-e on them

;; few examples of acceptable aurgument:

;; (insert-contents-tree "Tree/{a,b,c}")
;; (insert-contents-tree "Tree/a/b/c")
;; (insert-contents-tree "Tree/{a/aa,b,c}")
;; (insert-contents-tree "Tree/{a,b/bb,c/cc/ccc,d/dd/ddd/dddd,e,f,g}")
;; (insert-contents-tree "Tree/{a/aa,b/bb,e/f,m/n/o/p/q/{r,s,t/u/v/w}}")
;; (insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}")
;; (insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3,1.1.4},2/{8,8}}")
;; (insert-contents-tree "CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1/{a,b/{c,d/{e,f/{k,o}}},r},1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}")
;; (insert-contents-tree "TITLE/{1/2/{3/{4/{a,b/{c,d/{e,f/{k,o/b/b/b/b/{l,m,n,o/p}}}},r},5,6/{7,8,9,10/11/{12,13}}},14,15},2/2.1,3/3.1}")

;; few examples of illegal argument:

;; if any one of "{/" "{}" "{," ",/" ",}" ",{" "/," "/}" "}/" "}{"
;; or "{{" "//" ",," occurs in string
;; signal an error: Wrong format of argument
;; (insert-contents-tree "tree/a/d/e//f")

;; if string ends with "," or "{" or "/"
;; signal an error: Wrong format of argument
;; (insert-contents-tree "tree/a/d/e/f,")

;; if braces do not match
;; signal an error: Wrong format of argument, braces do not match, unclosed {s.
;; (insert-contents-tree "tree/{a/d/e/f,b/{g,c}")
;; signal an error: Wrong format of argument, unmatched braces, maybe too many }s.
;; (insert-contents-tree "tree/{a/d/e/f,b/g,c}}")

;; other
;; signal an error: Wrong format of argument
;; (insert-contents-tree "tree/{a,b,c},d")

;;; Code:
(defun insert-contents-tree (str)
  "For the sake of convenience, this func would expect an
argument in the same format as in the `mkdir -p' command.
For example M-x insert-contents-tree <RET> and then enter
belowing string:
CONTENTS TITLE/{1/1.1/{1.1.1/{1.1.1.1,1.1.1.2,1.1.1.3},1.1.2,1.1.3},2/2.1,3/3.1}
would insert following contents tree into current buffer (starts from
a new line after the cursor point):

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
"
  (interactive "sType a string to generate your tree: ")
  (let ((contents_tree "\n\n")
        (braces 0)
        (length_of_str 0)
        (level -1)
        (n 0)
        (ch "")
        slash_n
        (slash_tmp_flag nil)
        (slash_tmp_str "")
        lbrace_n
        (lbrace_tmp_str "")
        (first_siblings_lbrace_list nil)
        (lbrace_tmp_list nil)
        rbrace_n
        (rbrace_tmp_list nil)
        comma_n
        (comma_slash_lbrace 2)
        (comma_tmp_str "")
        (comma_ttmp_str "")
        (sib_flag_list nil)
        (JOINT '("├─" "└─"))
        (VB2S "│  ") ;vertical bar and 2 spaces
        (4SPACES "    "))
    (if (string-match "\\(^.+?\\)/" str)
        (progn
          (setq contents_tree (concat contents_tree (match-string 0 str) "\n")) ;CONTENTS TITLE
          (setq str (replace-match "/" nil nil str))
          (setq length_of_str (length str)))
      (error "Can't match the title"))
    (if (or (string-match "\\(/\\{2,\\}\\|{\\{2,\\}\\|,\\{2,\\}\\)" str)
            (string-match "\\({/\\|{}\\|{,\\|,/\\|,}\\|,{\\|/,\\|/}\\|}/\\|}{\\)" str)
            (string-match "[,/{]$" str))
        (error "Wrong format of argument"))
    (while (< n length_of_str)
      (if (< braces 0) (error "Wrong format of argument, unpaired braces, maybe too many }s"))
      (if (and (>= braces 0)
               (string= "{" (char-to-string (elt str n))))
          (setq braces (1+ braces)))
      (if (string= "}" (char-to-string (elt str n))) (setq braces (1- braces)))
      (setq n (1+ n)))
    (if (> braces 0) (error "Wrong format of argument, braces do not match, unclosed {s"))
    (if (< braces 0) (error "Wrong format of argument, unpaired braces, maybe too many }s"))
    (setq n 0)
    (while (< n length_of_str)
      (setq ch (char-to-string (elt str n)))
      (if (string= ch "/")
          (progn 
            (setq level (1+ level))
            (setq slash_n (1+ n))
            (while (not (or (>= slash_n length_of_str)
                            (string= "/" (char-to-string (elt str slash_n)))
                            (string= "{" (char-to-string (elt str slash_n)))
                            (string= "}" (char-to-string (elt str slash_n)))
                            (string= "," (char-to-string (elt str slash_n)))))
              (setq slash_tmp_str (concat slash_tmp_str (char-to-string (elt str slash_n))))
              (setq slash_n (1+ slash_n)))
            (if (string< "" slash_tmp_str)
                (progn ;write to contents_tree
                  (if (= slash_n length_of_str) ;end of str
                      (setq slash_tmp_str (concat (nth 1 JOINT) slash_tmp_str))
                    (progn
                      (if (or (string= "," (char-to-string (elt str slash_n)))
                              (string= "}" (char-to-string (elt str slash_n))))
                          (progn
                            (setq slash_tmp_str (concat (nth 1 JOINT) slash_tmp_str))
                            (setq slash_tmp_flag "do_nothing"))
                        (if (string= "/" (char-to-string (elt str slash_n)))
                            (progn
                              (setq slash_tmp_str (concat (nth 1 JOINT) slash_tmp_str))
                              (setq slash_tmp_flag nil))))))                  
                  (if (= level 0)
                      (setq contents_tree (concat contents_tree slash_tmp_str "\n"))
                    (progn ;level>0
                      (dolist (flag (last sib_flag_list level))
                        (if flag
                            (setq slash_tmp_str (concat VB2S slash_tmp_str))
                          (setq slash_tmp_str (concat 4SPACES slash_tmp_str))))
                      (setq contents_tree (concat contents_tree slash_tmp_str "\n"))))
                  (if (not (string= "do_nothing" slash_tmp_flag)) (push slash_tmp_flag sib_flag_list))
                  ))
            (setq n slash_n) ;increases n
            (setq slash_tmp_str "") ;reset slash_tmp_str
            ))
      (if (string= ch "{")
          (progn
            (setq lbrace_n (1+ n))
            (while (not (or (string= "/" (char-to-string (elt str lbrace_n)))
                            (string= "{" (char-to-string (elt str lbrace_n)))
                            (string= "}" (char-to-string (elt str lbrace_n)))
                            (string= "," (char-to-string (elt str lbrace_n)))))
              (setq lbrace_tmp_str (concat lbrace_tmp_str (char-to-string (elt str lbrace_n))))
              (setq lbrace_n (1+ lbrace_n)))
            (if (string< "" lbrace_tmp_str)
                (progn
                  (setq lbrace_tmp_list (list lbrace_tmp_str level))
                  (push lbrace_tmp_list first_siblings_lbrace_list)
                  (setq lbrace_tmp_str (concat (nth 0 JOINT) lbrace_tmp_str))
                  (if (= level 0)
                      (setq contents_tree (concat contents_tree lbrace_tmp_str "\n"))
                    (progn
                      (dolist (flag (last sib_flag_list level))
                        (if flag
                            (setq lbrace_tmp_str (concat VB2S lbrace_tmp_str))
                          (setq lbrace_tmp_str (concat 4SPACES lbrace_tmp_str))))
                      (setq contents_tree (concat contents_tree lbrace_tmp_str "\n"))))
                  (push t sib_flag_list))
              (error "Something goes wrong"))
            (setq n lbrace_n) ;increases n
            (setq lbrace_tmp_str "") ;reset lbrace_tmp_str
            ))
      (if (string= ch "}")
          (progn
            (if first_siblings_lbrace_list
                (setq rbrace_tmp_list (pop first_siblings_lbrace_list))) ;pop
            (or first_siblings_lbrace_list (setq level -1))
            (setq rbrace_n (1+ n))
            (if (and (/= rbrace_n length_of_str)
                     (< level 0))
                (error "Wrong format of argument"))
            (and (< rbrace_n length_of_str)
                 (or (string= "," (char-to-string (elt str rbrace_n)))
                     (string= "}" (char-to-string (elt str rbrace_n)))
                     (error "Wrong format of argument")))
            (setq n rbrace_n) ;increases n
            ))
      (if (string= ch ",")
          (progn
            (setq comma_n (1+ n))
            (while (not (or (>= comma_n length_of_str)
                            (string= "/" (char-to-string (elt str comma_n)))
                            (string= "}" (char-to-string (elt str comma_n)))
                            (string= "{" (char-to-string (elt str comma_n)))
                            (string= "," (char-to-string (elt str comma_n)))))
              (setq comma_tmp_str (concat comma_tmp_str (char-to-string (elt str comma_n))))
              (setq comma_n (1+ comma_n)))
            (and (= comma_n length_of_str)
                 (error "Wrong format of argument"))
            (setq n comma_n) ;increases n
            (if (string< "" comma_tmp_str)
                (progn ;find 1st sibling's level and write to contents_tree
                  (if first_siblings_lbrace_list
                      (setq level (car (cdr (car first_siblings_lbrace_list)))))
                  (or level
                      (error "Something wrong with the variable `level'"))
                  (if (string= "," (char-to-string (elt str comma_n)))
                      (progn
                        (setq comma_tmp_str (concat (nth 0 JOINT) comma_tmp_str))
                        (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) t))
                    (progn
                      (if (string= "}" (char-to-string (elt str comma_n)))
                          (progn
                            (setq comma_tmp_str (concat (nth 1 JOINT) comma_tmp_str))
                            (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) nil)))))
                  (if (string= "/" (char-to-string (elt str comma_n)))
                      (progn
                        (while (not (or (>= comma_n length_of_str)
                                        (string= "{" (char-to-string (elt str comma_n)))
                                        (string= "," (char-to-string (elt str comma_n)))
                                        (string= "}" (char-to-string (elt str comma_n)))))
                          (setq comma_n (1+ comma_n)))
                        (if (< comma_n length_of_str)
                            (progn
                              (if (string= "{" (char-to-string (elt str comma_n)))
                                  (progn
                                    (setq comma_slash_lbrace 2)
                                    (while (and (< comma_n length_of_str)
                                                (not (string= "}" (char-to-string (elt str comma_n)))))
                                      (setq comma_n (1+ comma_n))
                                      (if (string= "{" (char-to-string (elt str comma_n)))
                                          (setq comma_slash_lbrace (1+ comma_slash_lbrace))))
                                    (if (= comma_n length_of_str) ;out of range
                                        (error "Wrong format of argument, braces do not match"))
                                    (if (= (1+ comma_n) length_of_str) ;if comma_n points to the last character of string
                                        (error "Wrong format of argument, braces do not match"))
                                    (if (< (1+ comma_n) (- length_of_str 2)) ;if it's at least the third last ch
                                        (progn ;make sure comma_n won't go beyond the second last ch of str
                                          (while (and (< comma_n (1- length_of_str))
                                                      (> comma_slash_lbrace 0)
                                                      (string= "}" (char-to-string (elt str comma_n))))
                                            (setq comma_n (1+ comma_n))
                                            (setq comma_slash_lbrace (1- comma_slash_lbrace))))
                                      (progn ;comma_n points to the second last ch of str
                                        (setq comma_slash_lbrace (1- comma_slash_lbrace))
                                        (setq comma_ttmp_str (char-to-string (elt str (1+ comma_n))))
                                        (if (not (or (string= "}" comma_ttmp_str)
                                                     (string= "," comma_ttmp_str)))
                                            (error "Wrong format of argument"))
                                        (if (string= "}" comma_ttmp_str)
                                            (setq comma_slash_lbrace (1- comma_slash_lbrace)))))
                                    (if (= 0 comma_slash_lbrace) ;no siblings
                                        (progn
                                          (setq comma_tmp_str (concat (nth 1 JOINT) comma_tmp_str))
                                          (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) nil))
                                      (progn
                                        (setq comma_tmp_str (concat (nth 0 JOINT) comma_tmp_str))
                                        (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) t))))
                                (progn
                                  (if (string= "," (char-to-string (elt str comma_n)))
                                      (progn
                                        (setq comma_tmp_str (concat (nth 0 JOINT) comma_tmp_str))
                                        (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) t)))
                                  (if (string= "}" (char-to-string (elt str comma_n)))
                                      (progn
                                        (setq comma_tmp_str (concat (nth 1 JOINT) comma_tmp_str))
                                        (setcar (nthcdr (- (1- (length sib_flag_list)) level) sib_flag_list) nil))))))
                          )))
                  (if (or (not level) (= level 0))
                      (setq contents_tree (concat contents_tree comma_tmp_str "\n"))
                    (progn
                      (dolist (flag (last sib_flag_list level))
                        (if flag
                            (setq comma_tmp_str (concat VB2S comma_tmp_str))
                          (setq comma_tmp_str (concat 4SPACES comma_tmp_str))))
                      (setq contents_tree (concat contents_tree comma_tmp_str "\n")))))
              (error "Something goes wrong"))
            (setq comma_tmp_str "") ;reset comma_tmp_str
            )))
    (insert contents_tree)))

(provide 'insert-contents-tree)

;;; insert-contents-tree.el ends here
