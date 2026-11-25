---
id: 20260107000006
title: Vim Editor Commands Reference Guide
date: 2026-01-07 00:05
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [vim, editor, commands, reference, productivity]
links: []
---
# Log
- 2026-01-07 00:05 - Created note.

# Notes

# Vim Notes:

# In Command Mode Type these to create files and directories ,Note: Take care of pwd before creating.
:! touch new-file.txt
:! mkdir new-directory

x - delete the character the cursor is on 


press l then h to set the cursor position to that line if previously it was on different line.


w - hop forward to non white space char
b - hop backward to non white space char 

p - paste below the current cursor position and move the cursor at the first char of current pasted line 
P - paste above the current cursor position and move the cursor at the first char of current pasted line 

v - visual mode
V - visual Line mode

when we select anything with v and d (delete) it , then p (paste it) then the content move 1 postion right
because of how the cursor postion work , but P will paste it exactly the same location where it was


delete - d , c , s , x
d x stay in normal mode after delete
c s move to insert mode after delete 
d c delete char or words based on next command
x s delete single char

:reg

vim automatically populates what is called the numbered registers for us. As expected, these are registers from "0 to "9.
"0 will always have the content of the latest yank, and the others will have last 9 deleted text, being "1 the newest, and "9 the oldest. So if you yanked some text, you can always refer to it using "0p.


There are 4 read only registers: "., "%, ": and "#
The last inserted text is stored on ".
"% has the current file path, starting from the directory where vim was first opened.
": is the most recently executed command.
"# is the name of the alternate file,


insert 



i - insert before the cursor
I - insert at the beginning of the line
a - insert (append) after the cursor
A - insert (append) at the end of the line
o - append (open) a new line below the current line
O - append (open) a new line above the current line
ea - insert (append) at the end of the word

:echo stdpath("config")





Files and 
:Ex - Explore 
:Vex - Vertical Explore
:Sex - Split Explore

(C-w) + v - open a vertical split but focus on the existing one 
(C-w) + s - open a horizontal split but focus on the existing one 
(C-w) + o - open the current window buffer, but closes every other buffer

Editing the files 

:e - for editing the files
:e filename - to open files to edit

Marks and positions
:marks - list of marks

ma - set current position for mark A
`a - jump to position of mark A
y`a - yank text to position of mark A


m - create a mark 
then small letter - set local mark
capital letter - set Global mark 

and to move to that mark we press
'Letter

example - 

ma, mA , mb, mB - To set the marks 
'a , 'A , 'b , 'B - To reach that mark 


We can switch between current file and alternate files using (C-^)

"# is the name of the alternate file,
"% has the current file path, starting from the directory where vim was first opened.


JumpLists 
We can use jump list to hop files forward or backward 


:ju[mps]

:ju[mps] - list of jumps
Ctrl + i - go to newer position in jump list
Ctrl + o - go to older position in jump list


Quickfix 

With Rg and fzf
:Rg WORD

With Grep we have to provide filename
:grep WORD **/*.c



:copen
:cnext

execute a command in all the buffers in quickfix or location list
:cdo

:wq - write and quit
:wa - write all


Search and Replace

 
/search

:set hls ic

replace

Search and Replace one by one
:s/searchedword/replacedword<CR>

Search and Replace all at once
:s/searchedword/replacedword/g<CR>

Search and Replace all but confirming always
:s/searchedword/replacedword/gc<CR>

@Macro

Macros are saved in registers and we can edit the macros and save it 
again in same/another register and replay it as I want 


@Register



