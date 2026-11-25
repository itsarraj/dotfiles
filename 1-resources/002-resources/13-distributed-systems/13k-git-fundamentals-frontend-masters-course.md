---
id: 20241226154102
title: Git Fundamentals Frontend Masters Complete Course Notes
date: 2024-12-26 15:41
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [git, version-control, frontend-masters, tutorial, command-line]
links: []
---
# Log
- 2024-12-26 15:41 - Created note.

# Notes

# 

git config --get --global init.defaultBranch
master # this might be response so 

We do this
git config --global --unset init.defaultBranch

We have to ensure that rerere isn't true
git config --global rerere.enabled 
true # if true is output turn it off 

find .git 

sha are unique 
cat sha won't be readable by us
### from this command we can print out the contents of sha
git cat-file -p <sha>
- sha contains the tree and tree contain our files and files contains entirety of the file and not just changes.
- here tree is like directory and blob is like file.
tree - analogous to directory
blob - analogous to file



[username@hostname git-test-repo]$ git cat-file -p 5a997f228f7fef50292982d6a922170d451eaed3
tree b74e214d4665d18570d321a256c7be5c9292ec40
author uranium <uranium@chernobyl> 1735226835 +0530
committer uranium <uranium@chernobyl> 1735226835 +0530

inserting the datas

[username@hostname git-test-repo]$ git cat-file -p b74e214d4665d18570d321a256c7be5c9292ec40
100644 blob 53c25045af72e97d9994a62e2ebc8c0acf9717d2    asdad.md
100644 blob 53c25045af72e97d9994a62e2ebc8c0acf9717d2    cassad.dd

[username@hostname git-test-repo]$ git cat-file -p 53c25045af72e97d9994a62e2ebc8c0acf9717d2
djsadadjadk

---
### making first change
[username@hostname git-test-repo]$ git init
[username@hostname git-test-repo]$ nvim first.md
[username@hostname git-test-repo]$ git add first.md
[username@hostname git-test-repo]$ git commit -m "first file added"
[master (root-commit) efed0b9] first file added
 1 file changed, 1 insertion(+)
 create mode 100644 first.md

[username@hostname git-test-repo]$ git cat-file -p efed0b9
tree 2e6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
author uranium <uranium@chernobyl> 1735240604 +0530
committer uranium <uranium@chernobyl> 1735240604 +0530

first file added

-or-

#### With find .git, I got couple of sha
[username@hostname git-test-repo]$ find .git/
.git/objects/ef/ed0b98320869e1af5a51b1db11ca13d6289585
.git/objects/9c/59e24b8393179a5d712de4f990178df5734d99
.git/objects/2e/6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b

[username@hostname git-test-repo]$ git cat-file -p efed0b98320869e1af5a51b1db11ca13d6289585
tree 2e6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
author uranium <uranium@chernobyl> 1735240604 +0530
committer uranium <uranium@chernobyl> 1735240604 +0530

first file added

[username@hostname git-test-repo]$ git cat-file -p 2e6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
100644 blob 9c59e24b8393179a5d712de4f990178df5734d99    first.md

[username@hostname git-test-repo]$ git cat-file -p 9c59e24b8393179a5d712de4f990178df5734d99
first

### making second change
[username@hostname git-test-repo]$ nvim second.md
[username@hostname git-test-repo]$ git add second.md ;git commit -m "second file added"
[master 96251d8] second file added
 1 file changed, 1 insertion(+)
 create mode 100644 second.md

[username@hostname git-test-repo]$ git cat-file -p  96251d8
tree c2bd0cc40088082e6f7d8fe306ccdacc5efa4cd6
parent efed0b98320869e1af5a51b1db11ca13d6289585
author uranium <uranium@chernobyl> 1735241216 +0530
committer uranium <uranium@chernobyl> 1735241216 +0530

second file added

-or-

#### With find .git, I got couple of sha
[username@hostname git-test-repo]$  find .git/
.git/objects/96/251d88eba6279e7bff8bc42fbb72e2a4324a4b
.git/objects/ef/ed0b98320869e1af5a51b1db11ca13d6289585
.git/objects/9c/59e24b8393179a5d712de4f990178df5734d99
.git/objects/2e/6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
.git/objects/e0/19be006cf33489e2d0177a3837a2384eddebc5
.git/objects/c2/bd0cc40088082e6f7d8fe306ccdacc5efa4cd6

[username@hostname git-test-repo]$ git cat-file -p 96251d88eba6279e7bff8bc42fbb72e2a4324a4b
tree c2bd0cc40088082e6f7d8fe306ccdacc5efa4cd6
parent efed0b98320869e1af5a51b1db11ca13d6289585
author uranium <uranium@chernobyl> 1735241216 +0530
committer uranium <uranium@chernobyl> 1735241216 +0530

second file added

[username@hostname git-test-repo]$ git cat-file -p efed0b98320869e1af5a51b1db11ca13d6289585
tree 2e6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
author uranium <uranium@chernobyl> 1735240604 +0530
committer uranium <uranium@chernobyl> 1735240604 +0530

first file added

[username@hostname git-test-repo]$ git cat-file -p c2bd0cc40088082e6f7d8fe306ccdacc5efa4cd6
100644 blob 9c59e24b8393179a5d712de4f990178df5734d99    first.md
100644 blob e019be006cf33489e2d0177a3837a2384eddebc5    second.md

[username@hostname git-test-repo]$ git cat-file -p 2e6f4dc6f559b8dbb4f4e7b0de60b316ba24bd2b
100644 blob 9c59e24b8393179a5d712de4f990178df5734d99    first.md

[username@hostname git-test-repo]$ git cat-file -p 9c59e24b8393179a5d712de4f990178df5734d99
first

[username@hostname git-test-repo]$ git cat-file -p e019be006cf33489e2d0177a3837a2384eddebc5
second


## first analysis
- for each commit there is unique hash with data about tree and parents
- for each change in directory and file entirety has unique hash created after every commit
- child's parent sha is previous commit's sha
- tree is directory of updated file sha

the first's sha is the same sha that it had in previous commit. meaning our commit store pointers to the entire contents of that file. so, we did not update 'first', therefore the next commit contains 'first', but it contains the pointer to exact version. Than means at any point in time, we need only one commit to rebuild the repo.We can build everything about it, because that is how it works.


git is a acyclic graph

continue with this point

rewatch it and then move forward 
7. Commit Graph- Tree   Parent

update - 2024-12-27 14:19


[username@hostname git-test-repo]$ git config --get-regexp .
user.name uranium
user.email uranium@chernobyl
core.repositoryformatversion 0
core.filemode true
core.bare false
core.logallrefupdates true

[username@hostname git-test-repo]$ git config --remove-section fm

[username@hostname git-test-repo]$ git config --add fm.anu isbig
[username@hostname git-test-repo]$ git config --add fm.anshu isyoung
[username@hostname git-test-repo]$ git config --add fm.papa isgreat
[username@hostname git-test-repo]$ git config --add fm.maa isbest

[username@hostname git-test-repo]$ git config --get fm.maa

[username@hostname git-test-repo]$ git config --get-regexp fm
fm.anu isbig
fm.anshu isyoung
fm.papa isgreat
fm.maa isbest

[username@hostname git-test-repo]$ git config --add fm.anu isalsobad
[username@hostname git-test-repo]$ git config --get-all fm.anu
isbig
isalsobad




[username@hostname git-test-repo]$ git config --get-all fm.anu
isbig
isalsobad
first.md   .git/      second.md
[username@hostname git-test-repo]$ git config --unset fm.anu isbig
[username@hostname git-test-repo]$ git config --get-all fm.anu
isalsobad
[username@hostname git-test-repo]$ git config --unset fm.anu isalsobad
[username@hostname git-test-repo]$ git config --get-all fm.anu

-or- 

[username@hostname git-test-repo]$ git config --unset-all fm.anu


[username@hostname git-test-repo]$ git config --remove-section fm

git config --list --local


---
git config --global init.defaultBranch trunk

[username@hostname git-test-repo]$ git config --global init.defaultBranch trunk

[username@hostname git-test-repo]$ git init
Initialized empty Git repository in /home/uranium/git-test-repo/.git/

[username@hostname git-test-repo]$ git status
On branch trunk

No commits yet

nothing to commit (create/copy files and use "git add" to track)
[username@hostname git-test-repo]$ echo "A" >> README.md ; git add . ; git status ; git commit -m "added A in README.md";
On branch trunk

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   README.md

[trunk (root-commit) c48da92] added A in README.md
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
[username@hostname git-test-repo]$ echo "^C>> README.md ; git add . ; git status ; git commit -m "added A in README.md";
[username@hostname git-test-repo]$ ^Ct add -A && git commit -m "updated tmux and modified neovim snippet" && git push github master ; git push gitlab master;
[username@hostname git-test-repo]$ echo "B" >> second.md ; git add . ; git status ; git commit -m "added B in second.md";c^C
[username@hostname git-test-repo]$ git checkout foo
error: pathspec 'foo' did not match any file(s) known to git
[username@hostname git-test-repo]$ git branch
* trunk
[username@hostname git-test-repo]$ git branch foo
[username@hostname git-test-repo]$ git branch
  foo
* trunk

[username@hostname git-test-repo]$ git log --graph --decorate
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b (HEAD -> trunk, foo)
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md

[username@hostname git-test-repo]$ git checkout foo
Switched to branch 'foo'

[username@hostname git-test-repo]$ echo "B" >> second.md ; git add . ; git status ; git commit -m "added B in second.md";
On branch foo
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   second.md

[foo 9823795] added B in second.md
 1 file changed, 1 insertion(+)
 create mode 100644 second.md

[username@hostname git-test-repo]$ echo "C" >> second.md ; git add . ; git status ; git commit -m "added C in second.md";
On branch foo
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   second.md

[foo ca3857d] added C in second.md
 1 file changed, 1 insertion(+)

[username@hostname git-test-repo]$ git log
commit ca3857d87a10436503b8b26db8a15bd931801dfb (HEAD -> foo)
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:41:46 2024 +0530

    added C in second.md

commit 9823795691f28a2c707b20899b8b87a146d16360
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:41:35 2024 +0530

    added B in second.md

commit c48da927dc37172446aa5b6450db9bbdcb55f03b (trunk)
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:39:23 2024 +0530

    added A in README.md

[username@hostname git-test-repo]$ git log --graph --decorate
* commit ca3857d87a10436503b8b26db8a15bd931801dfb (HEAD -> foo)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 16:41:46 2024 +0530
|
|     added C in second.md
|
* commit 9823795691f28a2c707b20899b8b87a146d16360
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 16:41:35 2024 +0530
|
|     added B in second.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b (trunk)
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md

#### checkout to trunk 


[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ echo "D" >> README.md ; git add . ; git status ; git commit -m "added D in README.md";
On branch trunk
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[trunk e55d51f] added D in README.md
 1 file changed, 1 insertion(+)
[username@hostname git-test-repo]$ echo "E" >> README.md ; git add . ; git status ; git commit -m "added E in README.md";
On branch trunk
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[trunk 7a34d43] added E in README.md
 1 file changed, 1 insertion(+)
[username@hostname git-test-repo]$ git log --graph --decorate
* commit 7a34d430953eb64b3d6666a04b50513937928efe (HEAD -> trunk)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:48 2024 +0530
|
|     added E in README.md
|
* commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:18 2024 +0530
|
|     added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md
[username@hostname git-test-repo]$ git log --oneline
7a34d43 (HEAD -> trunk) added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git log --oneline foo
ca3857d (foo) added C in second.md
9823795 added B in second.md
c48da92 added A in README.md
[username@hostname git-test-repo]$


#### merge now

There is a common commit point between the two, this is referred to as the "best common ancestor".
"merge base" is the term for this in docs.

simply, the first in common parent is the best common ancestor.

The branch you're on is the target branch and the branch you name in <branchname> will be the <source> branch.

git merge <branchname>

Merge branch 'foo' into trunk-merge-foo
# Please enter a commit message to explain why this merge is necessary,
# especially if it merges an updated upstream into a topic branch.
#
# Lines starting with '#' will be ignored, and an empty message aborts
# the commit.

Merge made by the 'ort' strategy.
 second.md | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 second.md

[username@hostname git-test-repo]$ git log --graph --decorate
*   commit 254088db559f3a48dc3442f2c6c62c8482d14e39 (HEAD -> trunk-merge-foo)
|\  Merge: 7a34d43 ca3857d
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 18:27:57 2024 +0530
| |
| |     Merge branch 'foo' into trunk-merge-foo
| |
| * commit ca3857d87a10436503b8b26db8a15bd931801dfb (foo)
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 16:41:46 2024 +0530
| |
| |     added C in second.md
| |
| * commit 9823795691f28a2c707b20899b8b87a146d16360
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 16:41:35 2024 +0530
| |
| |     added B in second.md
| |
* | commit 7a34d430953eb64b3d6666a04b50513937928efe (trunk)
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 17:45:48 2024 +0530
| |
| |     added E in README.md
| |
* | commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
|/  Author: uranium <uranium@chernobyl>
|   Date:   Fri Dec 27 17:45:18 2024 +0530
|
|       added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md

[username@hostname git-test-repo]$ git log --oneline
254088d (HEAD -> trunk-merge-foo) Merge branch 'foo' into trunk-merge-foo
7a34d43 (trunk) added E in README.md
e55d51f added D in README.md
ca3857d (foo) added C in second.md
9823795 added B in second.md
c48da92 added A in README.md

--x--

[username@hostname git-test-repo]$ git log --graph --decorate --parents
*   commit 254088db559f3a48dc3442f2c6c62c8482d14e39 7a34d430953eb64b3d6666a04b50513937928efe ca3857d87a10436503b8b26db8a15bd931801dfb (HEAD -> trunk-merge-foo)
|\  Merge: 7a34d43 ca3857d
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 18:27:57 2024 +0530
| |
| |     Merge branch 'foo' into trunk-merge-foo
| |
| * commit ca3857d87a10436503b8b26db8a15bd931801dfb 9823795691f28a2c707b20899b8b87a146d16360 (foo)
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 16:41:46 2024 +0530
| |
| |     added C in second.md
| |
| * commit 9823795691f28a2c707b20899b8b87a146d16360 c48da927dc37172446aa5b6450db9bbdcb55f03b
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 16:41:35 2024 +0530
| |
| |     added B in second.md
| |
* | commit 7a34d430953eb64b3d6666a04b50513937928efe e55d51fc584f8ed4cdf7c0c10709ae17578239b1 (trunk)
| | Author: uranium <uranium@chernobyl>
| | Date:   Fri Dec 27 17:45:48 2024 +0530
| |
| |     added E in README.md
| |
* | commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1 c48da927dc37172446aa5b6450db9bbdcb55f03b
|/  Author: uranium <uranium@chernobyl>
|   Date:   Fri Dec 27 17:45:18 2024 +0530
|
|       added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md

[username@hostname git-test-repo]$ git log --oneline --parents
254088d 7a34d43 ca3857d (HEAD -> trunk-merge-foo) Merge branch 'foo' into trunk-merge-foo
7a34d43 e55d51f (trunk) added E in README.md
e55d51f c48da92 added D in README.md
ca3857d 9823795 (foo) added C in second.md
9823795 c48da92 added B in second.md
c48da92 added A in README.md




### creating a branch bar

[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ git checkout -b bar
Switched to a new branch 'bar'
[username@hostname git-test-repo]$ echo "X" >> bar.md ; git add . ; git status ; git commit -m "added X in bar.md";
On branch bar
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   bar.md

[bar 0c05104] added X in bar.md
 1 file changed, 1 insertion(+)
 create mode 100644 bar.md
[username@hostname git-test-repo]$ echo "Y" >> bar.md ; git add . ; git status ; git commit -m "added Y in bar.md";
On branch bar
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   bar.md

[bar 7b9771c] added Y in bar.md
 1 file changed, 1 insertion(+)
[username@hostname git-test-repo]$ git log --oneline --parents
7b9771c 0c05104 (HEAD -> bar) added Y in bar.md
0c05104 7a34d43 added X in bar.md
7a34d43 e55d51f (trunk) added E in README.md
e55d51f c48da92 added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git log --oneline
7b9771c (HEAD -> bar) added Y in bar.md
0c05104 added X in bar.md
7a34d43 (trunk) added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git log --graph ^C
[username@hostname git-test-repo]$ git log --graph --decorate --parents
* commit 7b9771c558544a2ea3a0e675ba35e967939511cf 0c05104f01c1070d528e4737988af9adef141ab3 (HEAD -> bar)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:03:08 2024 +0530
|
|     added Y in bar.md
|
* commit 0c05104f01c1070d528e4737988af9adef141ab3 7a34d430953eb64b3d6666a04b50513937928efe
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:02:58 2024 +0530
|
|     added X in bar.md
|
* commit 7a34d430953eb64b3d6666a04b50513937928efe e55d51fc584f8ed4cdf7c0c10709ae17578239b1 (trunk)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:48 2024 +0530
|
|     added E in README.md
|
* commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1 c48da927dc37172446aa5b6450db9bbdcb55f03b
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:18 2024 +0530
|
|     added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md
[username@hostname git-test-repo]$ git log --graph --decorate
* commit 7b9771c558544a2ea3a0e675ba35e967939511cf (HEAD -> bar)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:03:08 2024 +0530
|
|     added Y in bar.md
|
* commit 0c05104f01c1070d528e4737988af9adef141ab3
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:02:58 2024 +0530
|
|     added X in bar.md
|
* commit 7a34d430953eb64b3d6666a04b50513937928efe (trunk)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:48 2024 +0530
|
|     added E in README.md
|
* commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:18 2024 +0530
|
|     added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md
[username@hostname git-test-repo]$ [^C
[username@hostname git-test-repo]$

### in this case above only bar has diverged opposite to the previous case.
merge in bar 

[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ git merge bar
Updating 7a34d43..7b9771c
Fast-forward
 bar.md | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 bar.md
[username@hostname git-test-repo]$ git log --oneline
7b9771c (HEAD -> trunk, bar) added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git log --oneline --parents
7b9771c 0c05104 (HEAD -> trunk, bar) added Y in bar.md
0c05104 7a34d43 added X in bar.md
7a34d43 e55d51f added E in README.md
e55d51f c48da92 added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git log --graph --decorate
* commit 7b9771c558544a2ea3a0e675ba35e967939511cf (HEAD -> trunk, bar)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:03:08 2024 +0530
|
|     added Y in bar.md
|
* commit 0c05104f01c1070d528e4737988af9adef141ab3
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:02:58 2024 +0530
|
|     added X in bar.md
|
* commit 7a34d430953eb64b3d6666a04b50513937928efe
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:48 2024 +0530
|
|     added E in README.md
|
* commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:18 2024 +0530
|
|     added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md
[username@hostname git-test-repo]$ git log --graph --decorate --parents
* commit 7b9771c558544a2ea3a0e675ba35e967939511cf 0c05104f01c1070d528e4737988af9adef141ab3 (HEAD -> trunk, bar)
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:03:08 2024 +0530
|
|     added Y in bar.md
|
* commit 0c05104f01c1070d528e4737988af9adef141ab3 7a34d430953eb64b3d6666a04b50513937928efe
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 20:02:58 2024 +0530
|
|     added X in bar.md
|
* commit 7a34d430953eb64b3d6666a04b50513937928efe e55d51fc584f8ed4cdf7c0c10709ae17578239b1
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:48 2024 +0530
|
|     added E in README.md
|
* commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1 c48da927dc37172446aa5b6450db9bbdcb55f03b
| Author: uranium <uranium@chernobyl>
| Date:   Fri Dec 27 17:45:18 2024 +0530
|
|     added D in README.md
|
* commit c48da927dc37172446aa5b6450db9bbdcb55f03b
  Author: uranium <uranium@chernobyl>
  Date:   Fri Dec 27 16:39:23 2024 +0530

      added A in README.md
[username@hostname git-test-repo]$


### in this case above there was no commit message 
its best common ancestor is the tip of the trunk
take the commit and update the pointer
documentation of FF the Merge 
with linear history and no diversion 




## Rebase

note: see example below for best understanding
what happens in rebase is
when git rebase <targetbranch> is executed 
 
Git checks out (or switches to) the <targetbranch>, and then starts applying the commits from <currentbranch> on top of it.

Git replays the commits from <currentbranch> on top of <targetbranch>, rather than moving commits from <targetbranch> to <currentbranch>. The commits in <currentbranch> are the ones that get rewritten and applied on top of the <targetbranch>.

tip of <currentbranch> will point to the new latest commit, which will be the new commit history created by the rebase. The SHA will change because the commits are new and rewritten.


Imagine you have:

- `main` branch with commits: A → B → C
- `feature` branch with commits: D → E → F (starting from commit B)

Before the rebase:
```
main:     A---B---C
              \
feature:       D---E---F
```

After running `git rebase main` on `feature`, it would look like:
```
main:     A---B---C---D'---E'---F'
```

Now, commits D, E, and F appear as if they were made after C, even though they were originally created before C.

---

In essence, rebase **replays your changes** on top of the latest commit from another branch, making your commit history cleaner and linear.


A Git rebase graph illustrates how the history of a feature branch changes as a result of rebasing. When you use `git rebase`, you move the entire branch to a new base commit, which is typically the latest commit on the target branch (often `main` or `develop`).

### Here's a simple example to explain:

Let's say you have a `main` branch, and you create a feature branch (`feature-xyz`). Over time, commits are made to both branches:

```
main:          A---B---C
                           \
feature-xyz:          D---E---F
```

### Step 1: The initial state
- `main` has commits `A`, `B`, and `C`.
- `feature-xyz` diverges after commit `B` and has commits `D`, `E`, and `F`.

### Step 2: Rebase `feature-xyz` onto `main`
Now, if you run `git rebase main` from the `feature-xyz` branch, Git will replay the commits `D`, `E`, and `F` on top of the latest commit from `main` (`C`).

### Step 3: After rebase
The resulting commit graph will look like this:

```
main:          A---B---C---D'---E'---F'
```

- Git rewrites the commits `D`, `E`, and `F` to `D'`, `E'`, and `F'` as new commits that are based on commit `C`.
- The rebase action makes the feature branch history linear, as if the commits `D`, `E`, and `F` were made after `C`, even though they were originally created earlier.

### Key points to remember about rebase:
1. **Rewrites commit history**: Rebase alters the commit hashes because it creates new commits.
2. **Linear history**: Rebasing keeps the history clean and linear, unlike merging which introduces merge commits.
3. **Avoid rebasing shared branches**: If the feature branch has been pushed to a shared repository, rebasing could cause issues for other developers because the commit hashes change.

### Example Workflow:
1. Checkout to your feature branch:
   ```bash
   git checkout feature-xyz
   ```
2. Perform the rebase:
   ```bash
   git rebase main
   ```
3. Resolve any conflicts if necessary, and continue the rebase process:
   ```bash
   git rebase --continue
   ```
4. Push your rebased feature branch:
   ```bash
   git push --force
   ```

Rebasing helps keep your project history clean and linear, making it easier to follow and understand changes over time.


### Suggestion:
- **Never rebase on a public/shared branch**:  
  Rebase rewrites commit history, and when you rebase a branch that is shared with others, it can cause issues for collaborators because their local histories will conflict with the rewritten history.
  
- **Rebase is fine on personal or private branches**:  
  It's safe to rebase on personal or private branches, as you’re the only one working on them. This can help keep your commit history clean and linear without affecting anyone else.

update - 2024-12-30 12:15

### HEAD


[username@hostname git-test-repo]$ git branch
  bar
  foo
* trunk
  trunk-merge-foo
[username@hostname git-test-repo]$ git log --oneline
7b9771c (HEAD -> trunk, bar) added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname git-test-repo]$ git checkout foo
Switched to branch 'foo'
[username@hostname git-test-repo]$ git log --oneline
ca3857d (HEAD -> foo) added C in second.md
9823795 added B in second.md
c48da92 added A in README.md

[username@hostname git-test-repo]$ git checkout trunk-merge-foo
Switched to branch 'trunk-merge-foo'
[username@hostname git-test-repo]$ git log --oneline
254088d (HEAD -> trunk-merge-foo) Merge branch 'foo' into trunk-merge-foo
7a34d43 added E in README.md
e55d51f added D in README.md
ca3857d (foo) added C in second.md
9823795 added B in second.md
c48da92 added A in README.md

[username@hostname git-test-repo]$ ls ./.git
branches  COMMIT_EDITMSG  config  description  HEAD  hooks  index  info  logs  objects  ORIG_HEAD  refs
[username@hostname git-test-repo]$ ls ./.git/HEAD
./.git/HEAD
[username@hostname git-test-repo]$ cat ./.git/HEAD
ref: refs/heads/trunk-merge-foo

Above head is a pointer to currently active branch and simply in file it refer to that branch commit sha.

The HEAD file is a pointer to the currently active branch or commit. It typically references the branch name in refs/heads/, which indirectly points to the latest commit SHA of that branch.

### reflog

[username@hostname git-test-repo]$ git reflog
254088d (HEAD -> trunk-merge-foo) HEAD@{0}: checkout: moving from foo to trunk-merge-foo
ca3857d (foo) HEAD@{1}: checkout: moving from trunk to foo
7b9771c (trunk, bar) HEAD@{2}: merge bar: Fast-forward
7a34d43 HEAD@{3}: checkout: moving from bar to trunk
7b9771c (trunk, bar) HEAD@{4}: commit: added Y in bar.md
0c05104 HEAD@{5}: commit: added X in bar.md
7a34d43 HEAD@{6}: checkout: moving from trunk to bar
7a34d43 HEAD@{7}: checkout: moving from trunk-merge-foo to trunk
254088d (HEAD -> trunk-merge-foo) HEAD@{8}: merge foo: Merge made by the 'ort' strategy.
7a34d43 HEAD@{9}: checkout: moving from trunk to trunk-merge-foo
7a34d43 HEAD@{10}: commit: added E in README.md
e55d51f HEAD@{11}: commit: added D in README.md
c48da92 HEAD@{12}: checkout: moving from foo to trunk
ca3857d (foo) HEAD@{13}: checkout: moving from trunk to foo
c48da92 HEAD@{14}: checkout: moving from foo to trunk
ca3857d (foo) HEAD@{15}: commit: added C in second.md
9823795 HEAD@{16}: commit: added B in second.md
c48da92 HEAD@{17}: checkout: moving from trunk to foo
c48da92 HEAD@{18}: commit (initial): added A in README.md


[username@hostname git-test-repo]$ cat .git/
branches/       config          HEAD            index           logs/           ORIG_HEAD
COMMIT_EDITMSG  description     hooks/          info/           objects/        refs/

[username@hostname git-test-repo]$ cat .git/logs/
HEAD  refs/

[username@hostname git-test-repo]$ cat .git/logs/HEAD
0000000000000000000000000000000000000000 c48da927dc37172446aa5b6450db9bbdcb55f03b uranium <uranium@chernobyl> 1735297763 +0530  commit (initial): added A in README.md
c48da927dc37172446aa5b6450db9bbdcb55f03b c48da927dc37172446aa5b6450db9bbdcb55f03b uranium <uranium@chernobyl> 1735297874 +0530  checkout: moving from trunk to foo
c48da927dc37172446aa5b6450db9bbdcb55f03b 9823795691f28a2c707b20899b8b87a146d16360 uranium <uranium@chernobyl> 1735297895 +0530  commit: added B in second.md
9823795691f28a2c707b20899b8b87a146d16360 ca3857d87a10436503b8b26db8a15bd931801dfb uranium <uranium@chernobyl> 1735297906 +0530  commit: added C in second.md
ca3857d87a10436503b8b26db8a15bd931801dfb c48da927dc37172446aa5b6450db9bbdcb55f03b uranium <uranium@chernobyl> 1735298052 +0530  checkout: moving from foo to trunk
c48da927dc37172446aa5b6450db9bbdcb55f03b ca3857d87a10436503b8b26db8a15bd931801dfb uranium <uranium@chernobyl> 1735301331 +0530  checkout: moving from trunk to foo
ca3857d87a10436503b8b26db8a15bd931801dfb c48da927dc37172446aa5b6450db9bbdcb55f03b uranium <uranium@chernobyl> 1735301338 +0530  checkout: moving from foo to trunk
c48da927dc37172446aa5b6450db9bbdcb55f03b e55d51fc584f8ed4cdf7c0c10709ae17578239b1 uranium <uranium@chernobyl> 1735301718 +0530  commit: added D in README.md
e55d51fc584f8ed4cdf7c0c10709ae17578239b1 7a34d430953eb64b3d6666a04b50513937928efe uranium <uranium@chernobyl> 1735301748 +0530  commit: added E in README.md
7a34d430953eb64b3d6666a04b50513937928efe 7a34d430953eb64b3d6666a04b50513937928efe uranium <uranium@chernobyl> 1735304259 +0530  checkout: moving from trunk to trunk-merge-foo
7a34d430953eb64b3d6666a04b50513937928efe 254088db559f3a48dc3442f2c6c62c8482d14e39 uranium <uranium@chernobyl> 1735304277 +0530  merge foo: Merge made by the 'ort' strategy.
254088db559f3a48dc3442f2c6c62c8482d14e39 7a34d430953eb64b3d6666a04b50513937928efe uranium <uranium@chernobyl> 1735309899 +0530  checkout: moving from trunk-merge-foo to trunk
7a34d430953eb64b3d6666a04b50513937928efe 7a34d430953eb64b3d6666a04b50513937928efe uranium <uranium@chernobyl> 1735309905 +0530  checkout: moving from trunk to bar
7a34d430953eb64b3d6666a04b50513937928efe 0c05104f01c1070d528e4737988af9adef141ab3 uranium <uranium@chernobyl> 1735309978 +0530  commit: added X in bar.md
0c05104f01c1070d528e4737988af9adef141ab3 7b9771c558544a2ea3a0e675ba35e967939511cf uranium <uranium@chernobyl> 1735309988 +0530  commit: added Y in bar.md
7b9771c558544a2ea3a0e675ba35e967939511cf 7a34d430953eb64b3d6666a04b50513937928efe uranium <uranium@chernobyl> 1735311114 +0530  checkout: moving from bar to trunk
7a34d430953eb64b3d6666a04b50513937928efe 7b9771c558544a2ea3a0e675ba35e967939511cf uranium <uranium@chernobyl> 1735311117 +0530  merge bar: Fast-forward
7b9771c558544a2ea3a0e675ba35e967939511cf ca3857d87a10436503b8b26db8a15bd931801dfb uranium <uranium@chernobyl> 1735564187 +0530  checkout: moving from trunk to foo
ca3857d87a10436503b8b26db8a15bd931801dfb 254088db559f3a48dc3442f2c6c62c8482d14e39 uranium <uranium@chernobyl> 1735564284 +0530  checkout: moving from foo to trunk-merge-foo
[username@hostname git-test-repo]$

#### reflog recreate the files back

[username@hostname git-test-repo]$ git branch
  bar
  foo
  trunk
* trunk-merge-foo
[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ git branch
  bar
  foo
* trunk
  trunk-merge-foo
[username@hostname git-test-repo]$ git checkout -b baz
Switched to a new branch 'baz'
[username@hostname git-test-repo]$ nvim baz.md
[username@hostname git-test-repo]$ git commit -m 'baz file added'
On branch baz
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        baz.md

nothing added to commit but untracked files present (use "git add" to track)
[username@hostname git-test-repo]$ git commit -m 'baz file added'^C
[username@hostname git-test-repo]$ git add baz.md
[username@hostname git-test-repo]$ git commit -m 'baz file added'
[baz bac9f79] baz file added
 1 file changed, 1 insertion(+)
 create mode 100644 baz.md
[username@hostname git-test-repo]$ git checkout master
error: pathspec 'master' did not match any file(s) known to git
[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ git branch -D baz
Deleted branch baz (was bac9f79).
[username@hostname git-test-repo]$ git branch
  bar
  foo
* trunk
  trunk-merge-foo
[username@hostname git-test-repo]$ git merge ^C
[username@hostname git-test-repo]$ git cat^C
[username@hostname git-test-repo]$ git cat-file -p bac9f79]
fatal: Not a valid object name bac9f79]
[username@hostname git-test-repo]$ git reflog -4
7b9771c (HEAD -> trunk, bar) HEAD@{0}: checkout: moving from baz to trunk
bac9f79 HEAD@{1}: commit: baz file added
7b9771c (HEAD -> trunk, bar) HEAD@{2}: checkout: moving from trunk to baz
7b9771c (HEAD -> trunk, bar) HEAD@{3}: checkout: moving from trunk-merge-foo to trunk
[username@hostname git-test-repo]$ git cat-file -p bac9f79
tree c84ff0ab935b175176c5ef7fdedda06945639433
parent 7b9771c558544a2ea3a0e675ba35e967939511cf
author uranium <uranium@chernobyl> 1735566115 +0530
committer uranium <uranium@chernobyl> 1735566115 +0530

baz file added
[username@hostname git-test-repo]$ git cat-file -p c84ff0ab935b175176c5ef7fdedda06945639433
100644 blob d3045e2c2d21fcf774700b3d5fa681cf26b300ad    README.md
100644 blob 16858db7afb62f3e027d8f9379085d3567bcac62    bar.md
100644 blob 2e1b57a2f26ebb10068a9f86cd28996d498e1f2d    baz.md
[username@hostname git-test-repo]$ git cat-file -p 2e1b57a2f26ebb10068a9f86cd28996d498e1f2d
baz file
[username@hostname git-test-repo]$ git cat-file -p 2e1b57a2f26ebb10068a9f86cd28996d498e1f2d > baz.md
[username@hostname git-test-repo]$ cat baz.md
baz file

this was just a showoff to recover the file from,
we can simply use the sha to get the file back

#### cherry pick

[username@hostname git-test-repo]$ cat baz.md
baz file
[username@hostname git-test-repo]$  rm baz.md
[username@hostname git-test-repo]$ git cat-file -p 2e1b57a2f26ebb10068a9f86cd28996d498e1f2d > baz.md^C
[username@hostname git-test-repo]$ git reflog -8
7b9771c (HEAD -> trunk, bar) HEAD@{0}: checkout: moving from baz to trunk
bac9f79 HEAD@{1}: commit: baz file added
7b9771c (HEAD -> trunk, bar) HEAD@{2}: checkout: moving from trunk to baz
7b9771c (HEAD -> trunk, bar) HEAD@{3}: checkout: moving from trunk-merge-foo to trunk
254088d (trunk-merge-foo) HEAD@{4}: checkout: moving from foo to trunk-merge-foo
ca3857d (foo) HEAD@{5}: checkout: moving from trunk to foo
7b9771c (HEAD -> trunk, bar) HEAD@{6}: merge bar: Fast-forward
7a34d43 HEAD@{7}: checkout: moving from bar to trunk

#### just merge that sha

[username@hostname git-test-repo]$ git merge bac9f79
Updating 7b9771c..bac9f79
Fast-forward
 baz.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 baz.md
[username@hostname git-test-repo]$ cat baz.md
baz file
[username@hostname git-test-repo]$

##### Warning 
- in cases like this, if histories have diverged far enough, this could cause some problems as we wouldn't just be merging the one commit, but all the commits in between bac9f79 (from above case) and trunk

- In cases where the histories have significantly diverged, merging a specific commit (e.g., bac9f79) may not only include that commit but also all intermediate commits between bac9f79 and the current branch. This can lead to unintended changes being merged.

### Cherry pick

Given one or more existing commits, apply the change each one introduces, recording a new commit for each.This requires the working tree to be clean (no modification from the HEAD commit).

Cherry-picking applies the changes introduced by one or more specific existing commits to the current branch, creating new commits for each. This operation requires a clean working tree, meaning there should be no uncommitted changes from the current HEAD.

[username@hostname git-test-repo]$ git checkout -b new
Switched to a new branch 'new'
[username@hostname git-test-repo]$ echo "newww" >> new.md ; git add . ; git status ; git commit -m "added new i n new.md";
On branch new
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   new.md

[new a413c7a] added new i n new.md
 1 file changed, 1 insertion(+)
 create mode 100644 new.md
[username@hostname git-test-repo]$ cd
bar.md     baz.md     .git/      new.md     README.md
[username@hostname git-test-repo]$ cd ba
bar.md  baz.md
[username@hostname git-test-repo]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname git-test-repo]$ git branch -D new
Deleted branch new (was a413c7a).
[username@hostname git-test-repo]$ git cherry-pick a413c7a]
fatal: bad revision 'a413c7a]'
[username@hostname git-test-repo]$ git cherry-pick a413c7a
[trunk a51b61c] added new i n new.md
 Date: Mon Dec 30 20:17:07 2024 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 new.md
[username@hostname git-test-repo]$ cat new.md
newww
[username@hostname git-test-repo]$



### Remote 


[username@hostname remote-git]$ cd ..
[username@hostname ~]$ tree ./ -L 2 | grep git
├── git-test-repo
├── hello-git
├── remote-git
[username@hostname ~]$ cd remote-git/
[username@hostname remote-git]$ git remote add origin ../hello-git
fatal: not a git repository (or any of the parent directories): .git
[username@hostname remote-git]$ git init
Initialized empty Git repository in /home/uranium/remote-git/.git/
[username@hostname remote-git]$ git remote add origin ../hello-git
[username@hostname remote-git]$ git remote -v
origin  ../hello-git (fetch)
origin  ../hello-git (push)
[username@hostname remote-git]$


gitism

for single source of truth - origin
for fork - origin , main project - upstream

update - 2024-12-31 10:30


[username@hostname remote-git]$ git remote -v
origin  ../hello-git (fetch)
origin  ../hello-git (push)
[username@hostname remote-git]$ git fetch
remote: Enumerating objects: 29, done.
remote: Counting objects: 100% (29/29), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 29 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (29/29), 2.25 KiB | 230.00 KiB/s, done.
From ../hello-git
 * [new branch]      bar             -> origin/bar
 * [new branch]      foo             -> origin/foo
 * [new branch]      trunk           -> origin/trunk
 * [new branch]      trunk-merge-foo -> origin/trunk-merge-foo
[username@hostname remote-git]$ git log
fatal: your current branch 'trunk' does not have any commits yet
[username@hostname remote-git]$ git log origin/trunk
commit a51b61c4ea7171afcce6aedddab0730c3d89c5f6 (origin/trunk)
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 20:17:07 2024 +0530

    added new i n new.md

commit bac9f79eb1232e96a83c5f4fde6e0bb65d10f0f7
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 19:11:55 2024 +0530

    baz file added

commit 7b9771c558544a2ea3a0e675ba35e967939511cf (origin/bar)
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:03:08 2024 +0530

    added Y in bar.md

commit 0c05104f01c1070d528e4737988af9adef141ab3
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:02:58 2024 +0530

    added X in bar.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
[username@hostname remote-git]$ git log origin/trunk --oneline
a51b61c (origin/trunk) added new i n new.md
bac9f79 baz file added
7b9771c (origin/bar) added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname remote-git]$ git branch -a
  remotes/origin/bar
  remotes/origin/foo
  remotes/origin/trunk
  remotes/origin/trunk-merge-foo
[username@hostname remote-git]$ sudo su
[sudo] password for uranium:
[root@chernobyl remote-git]# ^C
[root@chernobyl remote-git]# exit
exit
[username@hostname remote-git]$ git merge origin/trunk
[username@hostname remote-git]$ git log
commit a51b61c4ea7171afcce6aedddab0730c3d89c5f6 (HEAD -> trunk, origin/trunk)
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 20:17:07 2024 +0530

    added new i n new.md

commit bac9f79eb1232e96a83c5f4fde6e0bb65d10f0f7
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 19:11:55 2024 +0530

    baz file added

commit 7b9771c558544a2ea3a0e675ba35e967939511cf (origin/bar)
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:03:08 2024 +0530

    added Y in bar.md

commit 0c05104f01c1070d528e4737988af9adef141ab3
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:02:58 2024 +0530

    added X in bar.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
[username@hostname remote-git]$ git log --oneline
a51b61c (HEAD -> trunk, origin/trunk) added new i n new.md
bac9f79 baz file added
7b9771c (origin/bar) added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname remote-git]$

### pull

this is simply fetch + merge 

git pull <remote> <branch>


[username@hostname remote-git]$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 320 bytes | 320.00 KiB/s, done.
From ../hello-git
   a51b61c..11305e8  trunk      -> origin/trunk
There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> trunk

[username@hostname remote-git]$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 323 bytes | 323.00 KiB/s, done.
From ../hello-git
 + 11305e8...759df93 trunk      -> origin/trunk  (forced update)
There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> trunk

[username@hostname remote-git]$ git branch --set-upstream-to=origin/trunk trunk
branch 'trunk' set up to track 'origin/trunk'.
[username@hostname remote-git]$ git pull
Updating a51b61c..759df93
Fast-forward
 README.md | 2 ++
 1 file changed, 2 insertions(+)
[username@hostname remote-git]$

The thing with the pull is that it has to set tracking information for the branch as there might be multiple remote , what am i refering to and most important which one from I have to pull.

The `git pull` command requires tracking information for the branch because there might be multiple remotes. It needs to know which remote repository and branch to pull changes from. If no tracking information is set, you must specify the remote and branch explicitly (e.g., `git pull <remote> <branch>`).

#### Rebasing suggestion for remote authority repo from prime 

when pulled instead of multiple merge commit, prefer to rebase the changes 

reasons
- a long lived branch with bunch of merge commits is much more difficult to revert.
- If every change is a single commit, then the ability to revert is very trivial.
- I prefer to test my changes against the current state of master not against the current state i have fetched.


---
chatgpt refactor it
The statements are mostly correct but could be refined for better clarity and precision. Here's an improved version:

---

**Tracking Information for `git pull`:**  
The `git pull` command requires tracking information for the current branch, especially when multiple remotes are configured. It needs to identify which remote repository and branch to pull changes from. If tracking information is not set, you must explicitly specify the remote and branch using `git pull <remote> <branch>`.

---

**Rebasing Instead of Merging for Remote Authority Repos:**  
When pulling changes from a remote authoritative repository (e.g., `origin`), it is often better to use rebasing instead of merging. Here’s why:  

- A long-lived branch with many merge commits is harder to read, manage, and revert if needed.  
- Rebasing ensures each change is a single commit, making reversion trivial when necessary.  
- Rebasing aligns your changes with the current state of the main branch (e.g., `master` or `main`), ensuring your work is tested against the latest code instead of an outdated state.  

To rebase when pulling, use:  
```bash
git pull --rebase <remote> <branch>
```
your opinion on this 
Rebasing Instead of Merging for Remote Authority Repos:

Rebasing instead of merging for remote authority repositories is often a good practice, but it depends on the workflow and the project's collaboration style. Here's my opinion:

### Advantages of Rebasing for Remote Authority Repos:
1. **Cleaner History**:
   - Rebasing avoids cluttering the commit history with unnecessary merge commits, making the history linear and easier to read.

2. **Simplified Reverts**:
   - With each change isolated in a single commit, reverting problematic changes becomes straightforward without needing to untangle merge commit dependencies.

3. **Current Context**:
   - Rebasing ensures your changes are tested and applied on top of the latest state of the authoritative branch, reducing the risk of conflicts or regression bugs.

4. **Aligns with Code Reviews**:
   - A linear history is often preferred during code reviews, as it clearly shows what changes are being introduced without the noise of merge commits.

---

### Caveats of Rebasing:
1. **Rewriting History**:
   - Rebasing rewrites commit history, which can be dangerous if you've already pushed your changes to a shared repository. This can cause confusion for collaborators.

2. **Potential for Mistakes**:
   - Rebasing requires more care than merging, especially in resolving conflicts, as it involves replaying changes on top of a new base.

3. **Not Ideal for Large Teams**:
   - In large teams or open-source projects, where many contributors are working on the same branch, rebasing can lead to issues if not done carefully, especially with forced updates.

---

### My Take:
- **Use Rebasing for Personal or Short-Lived Feature Branches**: When working on a feature branch that hasn't been shared, rebasing is ideal to keep your history clean and up-to-date with the authoritative repository.
  
- **Use Merging for Collaborative Long-Lived Branches**: In cases where multiple people work on the same branch, merging is safer because it preserves the shared history and avoids the risks of rewriting history.

Ultimately, the choice between rebasing and merging should align with your project's collaboration model and team preferences. For an authoritative repository, adopting a rebase-first policy can improve clarity, provided all team members are comfortable with the approach and potential risks.

# push

previously when we setup these then then at checkout branch 'bar' set up to track 'origin/bar'
[username@hostname remote-git]$ git branch --set-upstream-to=origin/trunk trunk
branch 'trunk' set up to track 'origin/trunk'.

[username@hostname remote-git]$ git checkout bar
branch 'bar' set up to track 'origin/bar'.
Switched to a new branch 'bar'
[username@hostname remote-git]$  nvim README.md
[username@hostname remote-git]$ git status
On branch bar
Your branch is up to date with 'origin/bar'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git add .
[username@hostname remote-git]$ git commit -m "changes from remote "
[bar 8459710] changes from remote
 1 file changed, 2 insertions(+)
[username@hostname remote-git]$ git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 12 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 298 bytes | 298.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To ../hello-git
   7b9771c..8459710  bar -> bar

after checking the remote repo we found the changes there

[username@hostname hello-git]$ git checkout trunk
Switched to branch 'trunk'
[username@hostname hello-git]$ git checkout bar
Switched to branch 'bar'
[username@hostname hello-git]$ git log
commit 8459710d767e91d99120f01f07c301011cad22eb (HEAD -> bar)
Author: cesium <cesium@chernobyl.com>
Date:   Tue Jan 7 23:40:30 2025 +0530

    changes from remote

commit 7b9771c558544a2ea3a0e675ba35e967939511cf
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:03:08 2024 +0530

    added Y in bar.md


# stashing 

git stash
git stash -m "message"

git stash list
git stash show [--index <index>]
git stash pop

git stash pop --index<index>

git log -S change
- -S is the change in file and not the message 

```
[username@hostname hello-git]$ cat README.md
A
D
E

A remote change
[username@hostname hello-git]$ git commit -m 'sdsd'^C
[username@hostname hello-git]$ git log -S D
commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md
[username@hostname hello-git]$

```



# Resolving conflicts with Merge

made a change on remote repo and on local repo changed and commit the changes.

when we will make some changes on hello git nad commit stuff and we come to remote git adn make some changes without commit
we will get error of uncommit change, suggestion will be to stash or commit.
so we will stash here then make a pull from hello-git,
after making the pull, we will pop the stash and commit as per needed.

remote git


[username@hostname remote-git]$ git stash
Saved working directory and index state WIP on trunk: 4ca7201 ----------------
[username@hostname remote-git]$ git stash list
stash@{0}: WIP on trunk: 4ca7201 ----------------
stash@{1}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash show
 README.md | 1 +
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ git stash pop
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 2 and 3 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (06d17af4955a96f789dbd6fbefc5ed36434ab2f4)
[username@hostname remote-git]$ git stash -m 'readme changes'
Saved working directory and index state On trunk: readme changes
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: readme changes
stash@{1}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ nmtui
[username@hostname remote-git]$ nmtui
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: readme changes
stash@{1}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash -m 'readme changes'^C
[username@hostname remote-git]$ echo "ANOTHER change" >> README.md
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: readme changes
stash@{1}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash -m 'added another changes'
Saved working directory and index state On trunk: added another changes
[username@hostname remote-git]$ echo "ANOTHER change" >> README.md
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: added another changes
stash@{1}: On trunk: readme changes
stash@{2}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash -m 'new another changes'
Saved working directory and index state On trunk: new another changes
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: new another changes
stash@{1}: On trunk: added another changes
stash@{2}: On trunk: readme changes
stash@{3}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$  git pull
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[username@hostname remote-git]$  git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 249 bytes | 249.00 KiB/s, done.
From ../hello-git
   eb5bac2..7bc1ca7  trunk      -> origin/trunk
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint:
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
[username@hostname remote-git]$ git log -S change
commit 4ca72018d038a6741581e269e7e61c8a56450780 (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 00:10:40 2025 +0530

    ----------------

commit 759df931f250ffde6e8c1e3979b7f7e503c91496
Author: uranium <uranium@chernobyl>
Date:   Tue Dec 31 12:48:25 2024 +0530

    A remote change
[username@hostname remote-git]$ git log
commit 4ca72018d038a6741581e269e7e61c8a56450780 (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 00:10:40 2025 +0530

    ----------------

commit a0738bee0d7e9282e75b4746ce96948da31578d2
Author: cesium <cesium@chernobyl.com>
Date:   Tue Jan 7 23:27:32 2025 +0530

    don't know about this commit

commit 759df931f250ffde6e8c1e3979b7f7e503c91496
Author: uranium <uranium@chernobyl>
Date:   Tue Dec 31 12:48:25 2024 +0530

    A remote change

commit a51b61c4ea7171afcce6aedddab0730c3d89c5f6
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 20:17:07 2024 +0530

    added new i n new.md

commit bac9f79eb1232e96a83c5f4fde6e0bb65d10f0f7
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 19:11:55 2024 +0530

    baz file added

commit 7b9771c558544a2ea3a0e675ba35e967939511cf
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:03:08 2024 +0530

    added Y in bar.md

commit 0c05104f01c1070d528e4737988af9adef141ab3
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:02:58 2024 +0530
[username@hostname remote-git]$ git log -S change
commit 4ca72018d038a6741581e269e7e61c8a56450780 (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 00:10:40 2025 +0530

    ----------------

commit 759df931f250ffde6e8c1e3979b7f7e503c91496
Author: uranium <uranium@chernobyl>
Date:   Tue Dec 31 12:48:25 2024 +0530

    A remote change
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: new another changes
stash@{1}: On trunk: added another changes
stash@{2}: On trunk: readme changes
stash@{3}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash pop --index<inde^C

[username@hostname remote-git]$ git log -S change^C
[username@hostname remote-git]$ git stash pop --index2
error: unknown option `index2'
usage: git stash pop [--index] [-q | --quiet] [<stash>]

    -q, --[no-]quiet      be quiet, only report errors
    --[no-]index          attempt to recreate the index

[username@hostname remote-git]$ git stash pop --index 2
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 2 and 4 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{2} (9f1e0ed7a0ee4d13f109dd0105754afdc8f03a7e)
[username@hostname remote-git]$ git diff
diff --git a/README.md b/README.md
index f9215f0..238fcc5 100755
--- a/README.md
+++ b/README.md
@@ -4,3 +4,4 @@ E

 A remote change
 downstream change
+downstream change
[username@hostname remote-git]$ git commit -m "added commmit in git"
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 2 and 4 different commits each, respectively.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git add .
[username@hostname remote-git]$ git commit -m "added commmit for changes from stash "
[trunk 4267c1b] added commmit for changes from stash
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ git log ^C
[username@hostname remote-git]$ git stash list^C
[username@hostname remote-git]$ git stash pop --index 2^C
[username@hostname remote-git]$ git stash list
stash@{0}: On trunk: new another changes
stash@{1}: On trunk: added another changes
stash@{2}: WIP on bar: c48da92 added A in README.md
[username@hostname remote-git]$ git stash pop --index 1
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Index was not unstashed.
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 3 and 4 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
(reverse-i-search)`add': git commit -m "^Cded commmit for changes from stash "
[username@hostname remote-git]$ git diff
diff --cc README.md
index 238fcc5,0f2862e..0000000
--- a/README.md
+++ b/README.md
@@@ -4,4 -4,4 +4,8 @@@

  A remote change
  downstream change
++<<<<<<< Updated upstream
 +downstream change
++=======
+ ANOTHER change
++>>>>>>> Stashed changes
[username@hostname remote-git]$ git commit -m "added commmit for changes from stash "
U       README.md
error: Committing is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
[username@hostname remote-git]$ git add .
[username@hostname remote-git]$ git commit -m "added commmit for another changes from stash "
[trunk 7ec20aa] added commmit for another changes from stash
 1 file changed, 4 insertions(+)
[username@hostname remote-git]$ git commit -m "added commmit for changes from stash "^C
[username@hostname remote-git]$ git diff
[username@hostname remote-git]$ git diff 7ec20aa
[username@hostname remote-git]$ ^C
[username@hostname remote-git]$


--
hello-git

[username@hostname hello-git]$ echo "upstream change" >> upstream.md
[username@hostname hello-git]$ git add .; git commit "small change"
error: pathspec 'small change' did not match any file(s) known to git
[username@hostname hello-git]$ git add .; git commit -m "small change"
[trunk ee11b6c] small change
 1 file changed, 2 insertions(+)
 create mode 100644 upstream.md
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git log
commit ee11b6c37a254d7e0bdf2f65ac51e295d174e048 (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 00:01:40 2025 +0530

    small change

commit 759df931f250ffde6e8c1e3979b7f7e503c91496
Author: uranium <uranium@chernobyl>
Date:   Tue Dec 31 12:48:25 2024 +0530

    A remote change

commit a51b61c4ea7171afcce6aedddab0730c3d89c5f6
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 20:17:07 2024 +0530

    added new i n new.md

commit bac9f79eb1232e96a83c5f4fde6e0bb65d10f0f7
Author: uranium <uranium@chernobyl>
Date:   Mon Dec 30 19:11:55 2024 +0530

    baz file added

commit 7b9771c558544a2ea3a0e675ba35e967939511cf
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:03:08 2024 +0530

    added Y in bar.md

commit 0c05104f01c1070d528e4737988af9adef141ab3
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 20:02:58 2024 +0530

    added X in bar.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530
[username@hostname hello-git]$ echo "upstream change" >> upstreaam.md
[username@hostname hello-git]$ git add .; git commit -m "small up change"
[trunk ed410da] small up change
 1 file changed, 1 insertion(+)
 create mode 100644 upstreaam.md
[username@hostname hello-git]$ echo "upstreasdasdam change" >> upstreaasadasdm.md
[username@hostname hello-git]$ git commit -m 'sdsd'
On branch trunk
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        upstreaasadasdm.md

nothing added to commit but untracked files present (use "git add" to track)
[username@hostname hello-git]$ ^C
[username@hostname hello-git]$ git add .; git commit -m "ddddddddddddddddddchange"
[trunk eb5bac2] ddddddddddddddddddchange
 1 file changed, 1 insertion(+)
 create mode 100644 upstreaasadasdm.md
[username@hostname hello-git]$ n^C
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git add .; git commit -m "ddddddddddddddddddchange"
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ echo "upstream change" >> upstream.md
[username@hostname hello-git]$ git status
On branch trunk
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   upstream.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ git status
On branch trunk
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   upstream.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ git add .; git commit -m "added upstream"
[trunk 7bc1ca7] added upstream
 1 file changed, 1 insertion(+)
[username@hostname hello-git]$

## worktrees




## conflicts


changes made in README.md file in 'hello-git' remote repo to make conflict with the local one, as I also made the changes in README.md in 'remote-git' local repo.

[username@hostname hello-git]$ git log -3
commit 291f00f87175e747781ed0a870eb44fbf60762d1 (HEAD -> trunk)
Merge: 2a959fa 3831d52
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:39:10 2025 +0530

    cleaned again

commit 2a959faaf83e4f96c7e42124e3692eebdd6f3fbd
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:33:53 2025 +0530

    added A+2

commit 3831d52d1f23fe56aabef6ca4960f1c7e44207f0
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:33:28 2025 +0530

    added A+1
[username@hostname hello-git]$ nvim README.md
[username@hostname hello-git]$ cat README.md
A+1
D
E
[username@hostname hello-git]$  git add .; git commit -m "Added A+1 in README.md"
[trunk 50dfab7] Added A+1 in README.md
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname hello-git]$ git log -1
commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md
[username@hostname hello-git]$


--

[username@hostname remote-git]$ git log -3
commit 291f00f87175e747781ed0a870eb44fbf60762d1 (HEAD -> trunk, origin/trunk)
Merge: 2a959fa 3831d52
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:39:10 2025 +0530

    cleaned again

commit 2a959faaf83e4f96c7e42124e3692eebdd6f3fbd
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:33:53 2025 +0530

    added A+2

commit 3831d52d1f23fe56aabef6ca4960f1c7e44207f0
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:33:28 2025 +0530

    added A+1
[username@hostname remote-git]$ nvim README.md
[username@hostname remote-git]$ cat README.md
A+2
D
E
[username@hostname remote-git]$ git add .; git commit -m "Added A+2 in README.md"
[trunk 4bab54f] Added A+2 in README.md
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$ git pull origin trunk
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 357 bytes | 357.00 KiB/s, done.
From ../hello-git
 * branch            trunk      -> FETCH_HEAD
   291f00f..50dfab7  trunk      -> origin/trunk
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Automatic merge failed; fix conflicts and then commit the result.
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+2
=======
A+1
>>>>>>> 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
D
E
[username@hostname remote-git]$
[username@hostname remote-git]$ git status

On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

Last commands done (5 commands done):
   pick 7ec20aa added commmit for another changes from stash
   pick df8bb15 added A+2
  (see more in file .git/rebase-merge/done)
Next command to do (1 remaining command):
   pick 6b1c6a2 added A+11
  (use "git rebase --edit-todo" to view and edit)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$

- thing to notice is the 
`>>>>>>> 50dfab7775da5eb75c96636bfb8115e99f9ccf4a`
is same as 
hello-git latest sha that we pulled 50dfab7775da5eb75c96636bfb8115e99f9ccf4a 

- Now, to work on conflicts we should prefer `git status` to figure out the conflicting files. there will be `both modified` in git status focus on those files to resolve it.

- We can abort it with `git merge --abort`

- Here I have updated the changed in README.md file,
There will be two cases if we accept our local changes, the `git status` will be empty as there is no change in file. 
But, We have to commit the merge.


[username@hostname remote-git]$ nvim README.md
[username@hostname remote-git]$ git diff
diff --cc README.md
index d34c9c8,4c12719..0000000
--- a/README.md
+++ b/README.md

[username@hostname remote-git]$ git add .; git commit -m "merged in upstream"
[trunk 3afc0f8] merged in upstream

[username@hostname remote-git]$ git log --graph
*   commit 3afc0f8a5a94fba6ae2758c047bd98a25a94b4df (HEAD -> trunk)
|\  Merge: 4bab54f 50dfab7
| | Author: cesium <cesium@chernobyl.com>
| | Date:   Wed Jan 8 04:05:50 2025 +0530
| |
| |     merged in upstream
| |
| * commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a (origin/trunk)
| | Author: cesium <cesium@chernobyl.com>
| | Date:   Wed Jan 8 03:40:52 2025 +0530
| |
| |     Added A+1 in README.md
| |
* | commit 4bab54f98d874c28bb20869f04fad890a16a395a
|/  Author: cesium <cesium@chernobyl.com>
|   Date:   Wed Jan 8 03:40:27 2025 +0530
|
|       Added A+2 in README.md
|
*   commit 291f00f87175e747781ed0a870eb44fbf60762d1
|\  Merge: 2a959fa 3831d52
| | Author: cesium <cesium@chernobyl.com>
| | Date:   Wed Jan 8 03:39:10 2025 +0530
| |
| |     cleaned again
| |
| * commit 3831d52d1f23fe56aabef6ca4960f1c7e44207f0
| | Author: cesium <cesium@chernobyl.com>
| | Date:   Wed Jan 8 03:33:28 2025 +0530
| |
| |     added A+1
| |
* | commit 2a959faaf83e4f96c7e42124e3692eebdd6f3fbd
|/  Author: cesium <cesium@chernobyl.com>
|   Date:   Wed Jan 8 03:33:53 2025 +0530
|
|       added A+2
|
* commit d4555085c9d80fd5a9d498a554b1fab692b6321d
[username@hostname remote-git]$


- again making a new conflict 

by change hello-git bar.md a little and pulling it from remote-git 
the thing is that after previous merge we have not informed the remote `hello-git` repo 
about our changes,I mean we have not pushed our changes in remote and pulling in changes 
so for every pull we get 2 commit one is the change on that repo another is merge commit.

[username@hostname hello-git]$ echo "no conflict" >> bar.md
[username@hostname hello-git]$  git add .; git commit -m "Added no conflict in bar.md"
[trunk 161ab6e] Added no conflict in bar.md
 1 file changed, 1 insertion(+)
[username@hostname hello-git]$ git log -1
commit 161ab6e67367dc8298c1f5f4c888b9dbba59c3ef (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:17 2025 +0530

    Added no conflict in bar.md


[username@hostname remote-git]$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 261 bytes | 261.00 KiB/s, done.
From ../hello-git
   e08f023..161ab6e  trunk      -> origin/trunk
Merge made by the 'ort' strategy.
 bar.md | 1 +
 1 file changed, 1 insertion(+)

[username@hostname remote-git]$ git log -3
commit 1411245a88ccfa8c074056abbafaced57434d1cc (HEAD -> trunk)
Merge: 9f24204 161ab6e
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:25 2025 +0530

    Merge branch 'trunk' of ../hello-git into trunk

commit 161ab6e67367dc8298c1f5f4c888b9dbba59c3ef (origin/trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:17 2025 +0530

    Added no conflict in bar.md

commit 3afc0f8a5a94fba6ae2758c047bd98a25a94b4df
Merge: 4bab54f 50dfab7
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:05:50 2025 +0530

    merged in upstream

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

commit 291f00f87175e747781ed0a870eb44fbf60762d1
Merge: 2a959fa 3831d52
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:39:10 2025 +0530
[username@hostname remote-git]$


[username@hostname remote-git]$ git log --oneline --graph
*   1411245 (HEAD -> trunk) Merge branch 'trunk' of ../hello-git into trunk
|\
| * 161ab6e (origin/trunk) Added no conflict in bar.md
* | 3afc0f8 merged in upstream
|\|
| * 50dfab7 Added A+1 in README.md
* | 4bab54f Added A+2 in README.md
|/
*   291f00f cleaned again


# Resolving conflicts with Rebase

if we replay a commit with conflict it will conflict again and again and again.


hello git changees

[username@hostname hello-git]$ git log -3
commit 1411245a88ccfa8c074056abbafaced57434d1cc (HEAD -> trunk)
Merge: 9f24204 161ab6e
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:25 2025 +0530

    Merge branch 'trunk' of ../hello-git into trunk

commit 161ab6e67367dc8298c1f5f4c888b9dbba59c3ef
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:17 2025 +0530

    Added no conflict in bar.md

commit 9f24204c5dc5f279cbb0ab89432d54a0e6daabba
Merge: c3f151c e08f023
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:32:50 2025 +0530

    Merge branch 'trunk' of ../hello-git into trunk
[username@hostname hello-git]$ vnim .n^C
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ nvim .
(failed reverse-i-search)`cm': ^Cear
[username@hostname hello-git]$ git add .; git commit -m "changes from hello for rebase conflict"
[trunk 535d4db] changes from hello for rebase conflict
 2 files changed, 2 insertions(+), 1 deletion(-)
[username@hostname hello-git]$ git log^C
(failed reverse-i-search)`hard': cp -r /home/cesium/.local/s^Cre/fonts/edge-display ./
(failed reverse-i-search)`hard': cp -r /home/cesium/.local/s^Cre/fonts/edge-display ./
[username@hostname hello-git]$ git log -3
commit 535d4db36c28cb0418378e2a8da79b4ed1094c7c (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 05:33:58 2025 +0530

    changes from hello for rebase conflict

commit 1411245a88ccfa8c074056abbafaced57434d1cc
Merge: 9f24204 161ab6e
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:25 2025 +0530

    Merge branch 'trunk' of ../hello-git into trunk

commit 161ab6e67367dc8298c1f5f4c888b9dbba59c3ef
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:17 2025 +0530

    Added no conflict in bar.md
[username@hostname hello-git]$ git add .; git commit -m "changes from hello for rebase conflict"^C
(failed reverse-i-search)`hard': cp -r /home/cesium/.local/s^Cre/fonts/edge-display ./
[username@hostname hello-git]$   git reset --hard HEAD~1
HEAD is now at 1411245 Merge branch 'trunk' of ../hello-git into trunk
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ git diff
diff --git a/README.md b/README.md
index d34c9c8..370ae0c 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+2
+A+3
 D
 E
diff --git a/bar.md b/bar.md
index 5276b60..7861beb 100755
--- a/bar.md
+++ b/bar.md
@@ -1,3 +1,4 @@
+First LINE Changed in hello-git bar
 X
 Y
 no conflict
[username@hostname hello-git]$ git status
On branch trunk
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md
        modified:   bar.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ git pull --rebase
error: cannot pull with rebase: You have unstaged changes.
error: Please commit or stash them.
[username@hostname hello-git]$ git add .; git commit -m "changes from hello for rebase conflict"
[trunk 142df15] changes from hello for rebase conflict
 2 files changed, 2 insertions(+), 1 deletion(-)
[username@hostname hello-git]$



remote git changes



[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ nvim .
(reverse-i-search)`cat': ^Ct README.md
[username@hostname remote-git]$ echo "LAST LINE Changed in remote-git bar" >> bar.md
[username@hostname remote-git]$ git diff
diff --git a/README.md b/README.md
index d34c9c8..0c09e52 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+2
+A+4
 D
 E
diff --git a/bar.md b/bar.md
index 5276b60..5565c44 100755
--- a/bar.md
+++ b/bar.md
@@ -3,3 +3,4 @@ Y
 no conflict
 no conflict
 no conflict
+LAST LINE Changed in remote-git bar
[username@hostname remote-git]$ git status
On branch trunk
Your branch is up to date with 'origin/trunk'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md
        modified:   bar.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ ^Rhad^C
(reverse-i-search)`hard':  git reset --^Crd HEAD~1
[username@hostname remote-git]$ n^C
[username@hostname remote-git]$ git add .; git commit -m "changes from remote for rebase conflict"
[trunk 5bb0b62] changes from remote for rebase conflict
 2 files changed, 2 insertions(+), 1 deletion(-)
[username@hostname remote-git]$ git status
On branch trunk
Your branch is ahead of 'origin/trunk' by 1 commit.
  (use "git push" to publish your local commits)

```
nothing to commit, working tree clean
(reverse-i-search)`': clear^C
(reverse-i-search)`--reb': git pull origin trunk ^Crebase
(failed reverse-i-search)`': git add .; git commit -m "changes from remote for rebase c^Cflict"
[username@hostname remote-git]$ git pull --rebase
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
c
From ../hello-git
   1411245..142df15  trunk      -> origin/trunk
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Auto-merging bar.md
error: could not apply 5bb0b62... changes from remote for rebase conflict
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config advice.mergeConflict false"
Could not apply 5bb0b62... changes from remote for rebase conflict
[username@hostname remote-git]$ cat bar.md
First LINE Changed in hello-git bar
X
Y
no conflict
no conflict
no conflict
LAST LINE Changed in remote-git bar
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+3
=======
A+4
>>>>>>> 5bb0b62 (changes from remote for rebase conflict)
D
E
[username@hostname remote-git]$
```

The changess here is that we are getting the remote change as shown as local
As we know when we rebase it checkout to upstream and run the commits so 
the head here is inverted in case of rebase 

look at perspective of checkout of rebase, then it makes perfect sense 
```
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+3
=======
A+4
>>>>>>> 5bb0b62 (changes from remote for rebase conflict)
D
E
[username@hostname remote-git]$
```

we will choose our conflict here, hello-git's change of A+3





```
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 142df15
Last command done (1 command done):
   pick 5bb0b62 changes from remote for rebase conflict
No commands remaining.
You are currently rebasing branch 'trunk' on '142df15'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   bar.md

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

[username@hostname remote-git]$ git diff
diff --cc README.md
index 370ae0c,0c09e52..0000000
--- a/README.md
+++ b/README.md

[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+3
=======
A+4
>>>>>>> 5bb0b62 (changes from remote for rebase conflict)
D
E
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ cat README.md
A+3
D
E
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 142df15
Last command done (1 command done):
   pick 5bb0b62 changes from remote for rebase conflict
No commands remaining.
You are currently rebasing branch 'trunk' on '142df15'.
  (all conflicts fixed: run "git rebase --continue")

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   bar.md

[username@hostname remote-git]$
```
after the making the changes the README.md got removed from git status.
because we looking at it from hello-git's (remote repo that we pull -rebase) 

there is a main reason not to use rebase here with pull because we will loose a conflict that should have been in logs

```
[username@hostname remote-git]$ git log --oneline --graph
* ec86e8a (HEAD -> trunk) changes from remote for rebase conflict
* 142df15 (origin/trunk) changes from hello for rebase conflict
*   1411245 Merge branch 'trunk' of ../hello-git into trunk
|\
| * 161ab6e Added no conflict in bar.md

[username@hostname remote-git]$ git log --oneline
ec86e8a (HEAD -> trunk) changes from remote for rebase conflict
142df15 (origin/trunk) changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
161ab6e Added no conflict in bar.md

```
- here below we can see that  A+4 clearly vanished from logs

```
[username@hostname remote-git]$ git log --oneline -p
ec86e8a (HEAD -> trunk) changes from remote for rebase conflict
diff --git a/bar.md b/bar.md
index 7861beb..8378ed5 100755
--- a/bar.md
+++ b/bar.md
@@ -4,3 +4,4 @@ Y
 no conflict
 no conflict
 no conflict
+LAST LINE Changed in remote-git bar
142df15 (origin/trunk) changes from hello for rebase conflict
diff --git a/README.md b/README.md
index d34c9c8..370ae0c 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+2
+A+3
 D
 E
diff --git a/bar.md b/bar.md
index 5276b60..7861beb 100755
--- a/bar.md
+++ b/bar.md
@@ -1,3 +1,4 @@
+First LINE Changed in hello-git bar
 X
 Y
 no conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
161ab6e Added no conflict in bar.md
diff --git a/bar.md b/bar.md
index b29a574..5276b60 100755
--- a/bar.md
+++ b/bar.md
@@ -2,3 +2,4 @@ X
 Y
 no conflict
 no conflict

```

- I went to reflog to find that commit but we lost that in logs

```
[username@hostname remote-git]$ git reflog
ec86e8a (HEAD -> trunk) HEAD@{0}: rebase (finish): returning to refs/heads/trunk
ec86e8a (HEAD -> trunk) HEAD@{1}: rebase (continue): changes from remote for rebase conflict
142df15 (origin/trunk) HEAD@{2}: pull --rebase (start): checkout 142df15f886b337e4f3cc0020d6d5556cff4135b
5bb0b62 HEAD@{3}: commit: changes from remote for rebase conflict
1411245 HEAD@{4}: reset: moving to HEAD~1
49ee806 HEAD@{5}: commit: changes from remote for rebase conflict
1411245 HEAD@{6}: reset: moving to HEAD~1


[username@hostname remote-git]$ git log -p 5bb0b62
commit 5bb0b62bcc4e7a013105290eadd45645755e7f21
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 05:35:46 2025 +0530

    changes from remote for rebase conflict

diff --git a/README.md b/README.md
index d34c9c8..0c09e52 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+2
+A+4
 D
 E
diff --git a/bar.md b/bar.md
index 5276b60..5565c44 100755
--- a/bar.md
+++ b/bar.md
@@ -3,3 +3,4 @@ Y
 no conflict
 no conflict
 no conflict
+LAST LINE Changed in remote-git bar

commit 1411245a88ccfa8c074056abbafaced57434d1cc
Merge: 9f24204 161ab6e
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:25 2025 +0530

    Merge branch 'trunk' of ../hello-git into trunk

commit 161ab6e67367dc8298c1f5f4c888b9dbba59c3ef
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 04:33:17 2025 +0530

    Added no conflict in bar.md

diff --git a/bar.md b/bar.md
```
There is no conflict commit above in main logs after rebase.
We simply resolved it and continued our rebase.

There is reason of loosing of information that's why it's not preferred.
above we accepted the hello-git (upstream, remote repo changes) 
now below we will accept our changes but from rebase checkout perspective, that will be my changes 

# rebasing practice

here we have selected our local change
```
[username@hostname remote-git]$ nvim .
(reverse-i-search)`': ^C
(reverse-i-search)`n': ^Cim .
[username@hostname remote-git]$ git add .; git commit -m "A+6"
[trunk d2333a3] A+6
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$ git pull origin trunk --rebase
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 339 bytes | 339.00 KiB/s, done.
From ../hello-git
 * branch            trunk      -> FETCH_HEAD
   142df15..11bdc28  trunk      -> origin/trunk
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
error: could not apply d2333a3... A+6
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config advice.mergeConflict false"
Could not apply d2333a3... A+6
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 11bdc28
Last commands done (2 commands done):
   pick ec86e8a changes from remote for rebase conflict
   pick d2333a3 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '11bdc28'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+5
=======
A+6
>>>>>>> d2333a3 (A+6)
D
E
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ cat README.md
A+6
D
E
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 11bdc28
Last commands done (2 commands done):
   pick ec86e8a changes from remote for rebase conflict
   pick d2333a3 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '11bdc28'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git rebase --continue
README.md: needs merge
You must edit all merge conflicts and then
mark them as resolved using git add
[username@hostname remote-git]$ git add .
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 11bdc28
Last commands done (2 commands done):
   pick ec86e8a changes from remote for rebase conflict
   pick d2333a3 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '11bdc28'.
  (all conflicts fixed: run "git rebase --continue")

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[username@hostname remote-git]$ git rebase --continue
[detached HEAD d185da8] A+6
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/trunk.
[username@hostname remote-git]$ git ^C
[username@hostname remote-git]$ git log online --graph
fatal: ambiguous argument 'online': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[username@hostname remote-git]$ git log --online
fatal: unrecognized argument: --online
[username@hostname remote-git]$ git log --oneonline
fatal: unrecognized argument: --oneonline
[username@hostname remote-git]$ git log --oneline
d185da8 (HEAD -> trunk) A+6
5f4810a changes from remote for rebase conflict
11bdc28 (origin/trunk) A+5
142df15 changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
```

```
[username@hostname remote-git]$ git log --oneline
d185da8 (HEAD -> trunk) A+6
5f4810a changes from remote for rebase conflict
11bdc28 (origin/trunk) A+5
142df15 changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk

[username@hostname remote-git]$ git log -p  d185da8
commit d185da8b8f97020e1d4e50532540f6ac1bc018da (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:25:45 2025 +0530

    A+6

diff --git a/README.md b/README.md
index d88127d..e66aa83 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+5
+A+6
 D
 E

commit 5f4810abbd4946019132f2878caa4507d764b8d6
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 05:35:46 2025 +0530

    changes from remote for rebase conflict

diff --git a/bar.md b/bar.md
index 7861beb..8378ed5 100755
--- a/bar.md
+++ b/bar.md
@@ -4,3 +4,4 @@ Y
 no conflict
 no conflict
 no conflict
+LAST LINE Changed in remote-git bar

commit 11bdc281a18f1b21f409b9aa08571b6f9a5819ae (origin/trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:25:38 2025 +0530

    A+5

diff --git a/README.md b/README.md
[username@hostname remote-git]$

```



- 

we added NEWLINE in hello-git README.md here 

then pull rebase to remote again, 
now we have to resolve the same conflict again.

```
[username@hostname remote-git]$ git log --oneline -4
d185da8 (HEAD -> trunk) A+6
5f4810a changes from remote for rebase conflict
11bdc28 (origin/trunk) A+5
142df15 changes from hello for rebase conflict
[username@hostname remote-git]$ git pull rebase
fatal: 'rebase' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[username@hostname remote-git]$ git pull origin trunk --rebase
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 360 bytes | 360.00 KiB/s, done.
From ../hello-git
 * branch            trunk      -> FETCH_HEAD
   11bdc28..6d4dc9c  trunk      -> origin/trunk
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
error: could not apply d185da8... A+6
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config advice.mergeConflict false"
Could not apply d185da8... A+6
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+5
NEWLINE
=======
A+6
>>>>>>> d185da8 (A+6)
D
E
[username@hostname remote-git]$ ^C
[username@hostname remote-git]$

```

```
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+5
NEWLINE
=======
A+6
>>>>>>> d185da8 (A+6)
D
E
[username@hostname remote-git]$ ^C
[username@hostname remote-git]$ (nni^C
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6d4dc9c
Last commands done (2 commands done):
   pick 5f4810a changes from remote for rebase conflict
   pick d185da8 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '6d4dc9c'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6d4dc9c
Last commands done (2 commands done):
   pick 5f4810a changes from remote for rebase conflict
   pick d185da8 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '6d4dc9c'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ cat README.md
A+6
NEWLINE
D
E
[username@hostname remote-git]$
```

now enable rerere

# 22. Reuse Recorded Resolutions.mp4


```
[username@hostname remote-git]$ cat README.md
A+6
NEWLINE
D
E
[username@hostname remote-git]$ git config --add  rerere.enabled true
[username@hostname remote-git]$ git diff
diff --cc README.md
index 3bc4f04,e66aa83..0000000
--- a/README.md
+++ b/README.md
@@@ -1,4 -1,3 +1,4 @@@
- A+5
+ A+6
 +NEWLINE
  D
  E
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6d4dc9c
Last commands done (2 commands done):
   pick 5f4810a changes from remote for rebase conflict
   pick d185da8 A+6
No commands remaining.
You are currently rebasing branch 'trunk' on '6d4dc9c'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git rebase --continue
README.md: needs merge
You must edit all merge conflicts and then
mark them as resolved using git add
[username@hostname remote-git]$ git add README.md
[username@hostname remote-git]$ git rebase --continue
[detached HEAD bc13505] A+6
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/trunk.
[username@hostname remote-git]$ gtit ^C
[username@hostname remote-git]$ git log --oneline -4
bc13505 (HEAD -> trunk) A+6
cd8cfe5 changes from remote for rebase conflict
6d4dc9c (origin/trunk) Added NEWLINE
11bdc28 A+5
[username@hostname remote-git]$ git log --oneline -6
bc13505 (HEAD -> trunk) A+6
cd8cfe5 changes from remote for rebase conflict
6d4dc9c (origin/trunk) Added NEWLINE
11bdc28 A+5
142df15 changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
[username@hostname remote-git]$ git log -p bc13505
commit bc13505e6283da46bd176c8b2c90ab89294ff26d (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:25:45 2025 +0530

    A+6

diff --git a/README.md b/README.md
index 3bc4f04..803783d 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,4 @@
-A+5
+A+6
 NEWLINE
 D
 E

commit cd8cfe511c34165f7d57f6004102da55c4ae611d
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 05:35:46 2025 +0530

    changes from remote for rebase conflict

diff --git a/bar.md b/bar.md
index 7861beb..8378ed5 100755
--- a/bar.md
+++ b/bar.md
@@ -4,3 +4,4 @@ Y
 no conflict
 no conflict
 no conflict
+LAST LINE Changed in remote-git bar

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9 (origin/trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 11bdc281a18f1b21f409b9aa08571b6f9a5819ae
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:25:38 2025 +0530

    A+5

diff --git a/README.md b/README.md
index 370ae0c..d88127d 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+3
+A+5
 D
 E

commit 142df15f886b337e4f3cc0020d6d5556cff4135b
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 05:36:17 2025 +0530

    changes from hello for rebase conflict

diff --git a/README.md b/README.md
index d34c9c8..370ae0c 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
[username@hostname remote-git]$ V^C
[username@hostname remote-git]$

```
the newline commit is at the bottom now 

added 
this is 
```
[username@hostname hello-git]$ git add .; git commit -m "Added rerere in new  "
[trunk 677ed7c] Added rerere in new
 1 file changed, 2 insertions(+)
[username@hostname hello-git]$ cat new.md
newww

added rerere
```

```
[username@hostname remote-git]$ cat new.md
newww
[username@hostname remote-git]$ git config --local --list
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
remote.origin.url=../hello-git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.trunk.remote=origin
branch.trunk.merge=refs/heads/trunk
branch.bar.remote=origin
branch.bar.merge=refs/heads/bar
pull.rebase=false
rerere.enabled=true
[username@hostname remote-git]$ git pull origin trunk --rebase
error: Pulling is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
hint: as appropriate to mark resolution and make a commit.
fatal: Exiting because of an unresolved conflict.
[username@hostname remote-git]$ git rebase --abort
[username@hostname remote-git]$ git pull origin trunk --rebase
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 254 bytes | 254.00 KiB/s, done.
From ../hello-git
 * branch            trunk      -> FETCH_HEAD
 + 09fffa0...677ed7c trunk      -> origin/trunk  (forced update)
Successfully rebased and updated refs/heads/trunk.
[username@hostname remote-git]$ git ^C
[username@hostname remote-git]$ git log --oneline -6
aa92237 (HEAD -> trunk) A+6
cbfe0c9 changes from remote for rebase conflict
677ed7c (origin/trunk) Added rerere in new
6d4dc9c Added NEWLINE
11bdc28 A+5
142df15 changes from hello for rebase conflict
[username@hostname remote-git]$ git log -p  677ed7c
commit 677ed7c1ff6005d32246b23257869b66e5383daf (origin/trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:53:48 2025 +0530

    Added rerere in new

diff --git a/new.md b/new.md
index 1eaa3b3..9a4e0e0 100755
--- a/new.md
+++ b/new.md
@@ -1 +1,3 @@
 newww
+
+added rerere

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 11bdc281a18f1b21f409b9aa08571b6f9a5819ae
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:25:38 2025 +0530

    A+5

diff --git a/README.md b/README.md
index 370ae0c..d88127d 100755
[username@hostname remote-git]$
```

# 23. Ours   Theirs.mp4


Ours is the change of the current branch
Theirs is the change of the incomming branch

git checkout --ours README.md #use "ours" change
git checkout --theirs README.md #use "theirs" change

```
[username@hostname remote-git]$ nvim
bar.md      baz.md      .git/       newfile.md  new.md      README.md
[username@hostname remote-git]$ nvim README.md
[username@hostname remote-git]$ cat README.md
A+8
NEWLINE
D
E
[username@hostname remote-git]$ git -A; git commit -m "A+7";
unknown option: -A
usage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--no-lazy-fetch]
           [--no-optional-locks] [--no-advice] [--bare] [--git-dir=<path>]
           [--work-tree=<path>] [--namespace=<name>] [--config-env=<name>=<envvar>]
           <command> [<args>]
On branch trunk
Your branch is ahead of 'origin/trunk' by 2 commits.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git .; git commit -m "A+7";
git: '.' is not a git command. See 'git --help'.

The most similar commands are
        am
        gc
        mv
        mw
        p4
        rm
On branch trunk
Your branch is ahead of 'origin/trunk' by 2 commits.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git add .; git commit -m "A+7";
[trunk afe17ec] A+7
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$   git reset --hard HEAD~1
HEAD is now at aa92237 A+6
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ tmux-sessionizer
find: ‘/home/cesium/contributions’: No such file or directory
[username@hostname remote-git]$ git add .; git commit -m "A+*";
[trunk ef810d3] A+*
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$   git reset --hard HEAD~1
HEAD is now at aa92237 A+6
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ git add .; git commit -m "A+8";
[trunk c1cd86f] A+8
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), 348 bytes | 348.00 KiB/s, done.
From ../hello-git
   677ed7c..6becc5f  trunk      -> origin/trunk
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Recorded preimage for 'README.md'
Automatic merge failed; fix conflicts and then commit the result.
[username@hostname remote-git]$ git status
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 3 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git diff
diff --cc README.md
index 852c103,679fd69..0000000
--- a/README.md
+++ b/README.md
@@@ -1,4 -1,4 +1,8 @@@
++<<<<<<< HEAD
 +A+8
++=======
+ A+7
++>>>>>>> 6becc5fc03080e98e35f4bae1d8123f151345070
  NEWLINE
  D
  E
[username@hostname remote-git]$ git checkout --ours README.md
Updated 1 path from the index
[username@hostname remote-git]$ cat README.md
A+8
NEWLINE
D
E
[username@hostname remote-git]$ git status
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 3 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git add README.md
[username@hostname remote-git]$ git status
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 3 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

[username@hostname remote-git]$ git commit -m "merged the ours A+8"
Recorded resolution for 'README.md'.
[trunk 412dc0f] merged the ours A+8
[username@hostname remote-git]$ git log oneline -3
fatal: ambiguous argument 'oneline': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
[username@hostname remote-git]$ git log --oneline -3
412dc0f (HEAD -> trunk) merged the ours A+8
6becc5f (origin/trunk) A+7
c1cd86f A+8
[username@hostname remote-git]$ git log --oneline -6
412dc0f (HEAD -> trunk) merged the ours A+8
6becc5f (origin/trunk) A+7
c1cd86f A+8
aa92237 A+6
cbfe0c9 changes from remote for rebase conflict
677ed7c Added rerere in new
[username@hostname remote-git]$ git log --oneline -6 --graph
*   412dc0f (HEAD -> trunk) merged the ours A+8
|\
| * 6becc5f (origin/trunk) A+7
* | c1cd86f A+8
* | aa92237 A+6
* | cbfe0c9 changes from remote for rebase conflict
|/
* 677ed7c Added rerere in new
[username@hostname remote-git]$ git status
On branch trunk
Your branch is ahead of 'origin/trunk' by 4 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
[username@hostname remote-git]$ git push
Enumerating objects: 16, done.
Counting objects: 100% (15/15), done.
Delta compression using up to 12 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (10/10), 1.11 KiB | 1.11 MiB/s, done.
Total 10 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
To ../hello-git
   6becc5f..412dc0f  trunk -> trunk
[username@hostname remote-git]$
```

time for rebase with ours and theirs

first we want the changes in our(current branch) and not incomming branch.
In case of rebase it works the like we saw before the HEAD will be the incomming change so 
if we use `git checkout --ours README.md` then the HEAD will be the resolution.

also in these cases the entire commit with changes is used to resolve,
So prefer to do manual changes.

```
(failed reverse-i-search)read': git add .; git commit -m "merged in upst^Cam"
[username@hostname remote-git]$ nvim .
[username@hostname remote-git]$ git add . ;git commit -m "A+10"
[trunk 2bd040b] A+10
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$ git status
On branch trunk
Your branch and 'origin/trunk' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
(failed reverse-i-search)`PUSHC': ^C
(failed reverse-i-search)`PULL': ^C
(failed reverse-i-search)`': git add . ;git commit -m "^C10"
[username@hostname remote-git]$ git log --oneline -6 --graph
* 2bd040b (HEAD -> trunk) A+10
*   412dc0f merged the ours A+8
|\
| * 6becc5f A+7
* | c1cd86f A+8
* | aa92237 A+6
* | cbfe0c9 changes from remote for rebase conflict
|/
[username@hostname remote-git]$ git pull --rebase
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
error: could not apply 2bd040b... A+10
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config advice.mergeConflict false"
Recorded preimage for 'README.md'
Could not apply 2bd040b... A+10
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6de00e3
Last command done (1 command done):
   pick 2bd040b A+10
No commands remaining.
You are currently rebasing branch 'trunk' on '6de00e3'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ cat README.md
<<<<<<< HEAD
A+9
=======
A+10
>>>>>>> 2bd040b (A+10)
NEWLINE
D
E
[username@hostname remote-git]$ git checkout --ours README.md
Updated 1 path from the index
[username@hostname remote-git]$ cat README.md
A+9
NEWLINE
D
E
[username@hostname remote-git]$ git checkout --theirs README.md
Updated 1 path from the index
[username@hostname remote-git]$ cat README.md
A+10
NEWLINE
D
E
[username@hostname remote-git]$




[username@hostname remote-git]$ git checkout --theirs README.md
Updated 1 path from the index
[username@hostname remote-git]$ cat README.md
A+10
NEWLINE
D
E
[username@hostname remote-git]$ git log --oneline -6 --graph
* 6de00e3 (HEAD, origin/trunk) A+9
*   412dc0f merged the ours A+8
|\
| * 6becc5f A+7
* | c1cd86f A+8
* | aa92237 A+6
* | cbfe0c9 changes from remote for rebase conflict
|/
[username@hostname remote-git]$ ^C
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6de00e3
Last command done (1 command done):
   pick 2bd040b A+10
No commands remaining.
You are currently rebasing branch 'trunk' on '6de00e3'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname remote-git]$ git add .
[username@hostname remote-git]$ git status
interactive rebase in progress; onto 6de00e3
Last command done (1 command done):
   pick 2bd040b A+10
No commands remaining.
You are currently rebasing branch 'trunk' on '6de00e3'.
  (all conflicts fixed: run "git rebase --continue")

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[username@hostname remote-git]$ git diff
[username@hostname remote-git]$ git diff README.md
[username@hostname remote-git]$ git commit -m "A+10 + --theirs (means my local/current branch changes is accepted)"
Recorded resolution for 'README.md'.
[detached HEAD 5d2bd63] A+10 + --theirs (means my local/current branch changes is accepted)
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname remote-git]$ git log --oneline -6 --graph
* 5d2bd63 (HEAD) A+10 + --theirs (means my local/current branch changes is accepted)
* 6de00e3 (origin/trunk) A+9
*   412dc0f merged the ours A+8
|\
| * 6becc5f A+7
* | c1cd86f A+8
* | aa92237 A+6
[username@hostname remote-git]$



```
# 24. Interactive Rebase.mp4

```
[username@hostname remote-git]$ git log --oneline -6 --graph
* 5d2bd63 (HEAD) A+10 + --theirs (means my local/current branch changes is accepted)
* 6de00e3 (origin/trunk) A+9
*   412dc0f merged the ours A+8
|\
| * 6becc5f A+7
* | c1cd86f A+8
* | aa92237 A+6
[username@hostname remote-git]$ cat README.md
A+10
NEWLINE
D
E
[username@hostname remote-git]$  echo "1" >> README.md
[username@hostname remote-git]$ git add .; git commit -m "1 added to the end";
[detached HEAD 6698632] 1 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$  echo "2" >> README.md
[username@hostname remote-git]$ git add .; git commit -m "2 added to the end";
[detached HEAD 54f881f] 2 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$  echo "3" >> README.md
[username@hostname remote-git]$ git add .; git commit -m "3 added to the end";
[detached HEAD da75bbe] 3 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ git log --oneline -6
da75bbe (HEAD) 3 added to the end
54f881f 2 added to the end
6698632 1 added to the end
5d2bd63 A+10 + --theirs (means my local/current branch changes is accepted)
6de00e3 (origin/trunk) A+9
412dc0f merged the ours A+8
[username@hostname remote-git]$
```
To begin an interactive rebase we need to provide a point in time to rebase with. Typically, the simplest way to do this is with `HEAD~<number>`. `HEAD~1` means one commit back from `HEAD`.Since we did 3 commits we would use `HEAD~3` to select the base where we were before our 3 commits.

```
In Git, a **commitish** is a term that refers to any reference that can be resolved to a specific commit. It can be used in place of a commit hash (the unique identifier for a commit) or a more general reference like a branch name, tag, or even a relative commit reference.

Here are some examples of what can be considered a **commitish**:

1. **Commit Hash**: The full or abbreviated SHA-1 hash of a commit (e.g., `abc1234` or `d0e0e1b`).
   - Example: `git checkout abc1234`

2. **Branch Name**: The name of a branch, like `master`, `dev`, or any other branch in the repository.
   - Example: `git checkout master`

3. **Tag Name**: The name of a tag in the repository (e.g., `v1.0`, `release-2025`).
   - Example: `git checkout v1.0`

4. **Relative References**: Git supports using relative references to a commit, such as `HEAD^` (the parent of the current commit), `HEAD~2` (two commits before HEAD), or `HEAD~` (the most recent commit before the current one).
   - Example: `git checkout HEAD~2`

5. **Branch Name with a Specific Commit**: You can also use a combination of a branch name and a commit, like `branch-name~2` (the second-to-last commit on `branch-name`).
   - Example: `git checkout dev~2`

In short, a **commitish** is any way to specify a commit, either by its hash, reference name, or using relative positions from a reference. This allows you to work with commits in a more flexible manner in Git commands.
```

```
git rebase -i <commitish>
```
that means rebase <commitish>, inveractively, to the current commit (`HEAD` in this case) 

there will be editor with all the options. Read them carefully.

--
I will squash 3 commits i made above, if made a mistake use reflog to get back to original commit   

#### set vim as default is vi for core editor for git message prompts
git config --global core.editor vim

```
pick 11872da 1 added to the end
s 18cf370 2 added to the end
s 94097a4 3 added to the end

# Rebase 2bd040b..94097a4 onto 2bd040b (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#         create a merge commit using the original merge commit's
#         message (or the oneline, if no original merge commit was
#         specified); use -c <commit> to reword the commit message
# u, update-ref <ref> = track a placeholder for the <ref> to be updated
#                       to this position in the new commits. The <ref> is
#                       updated at the end of the rebase
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
~
~
                                                                    34,1          All


```


```
# This is a combination of 3 commits.
# This is the 1st commit message:

1 through 3 added to the end


# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Thu Jan 9 01:10:54 2025 +0530
#
# interactive rebase in progress; onto 2bd040b
# Last commands done (3 commands done):
#    squash 18cf370 2 added to the end
#    squash 94097a4 3 added to the end
# No commands remaining.
# You are currently rebasing branch 'trunk' on '2bd040b'.
#
# Changes to be committed:
#       modified:   README.md
#
~
~
                                                                    1,11          All
```
```
[username@hostname remote-git]$ git log --oneline -6
2bd040b (HEAD -> trunk) A+10
412dc0f merged the ours A+8
6becc5f A+7
c1cd86f A+8
aa92237 A+6
cbfe0c9 changes from remote for rebase conflict
[username@hostname remote-git]$ echo "1" >> README.md
[username@hostname remote-git]$  git add .; git commit -m "1 added to the end";
[trunk 11872da] 1 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ echo "2" >> README.md
[username@hostname remote-git]$  git add .; git commit -m "2 added to the end";
[trunk 18cf370] 2 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ echo "3" >> README.md
[username@hostname remote-git]$  git add .; git commit -m "3 added to the end";
[trunk 94097a4] 3 added to the end
 1 file changed, 1 insertion(+)
[username@hostname remote-git]$ git log --oneline -6
94097a4 (HEAD -> trunk) 3 added to the end
18cf370 2 added to the end
11872da 1 added to the end
2bd040b A+10
412dc0f merged the ours A+8
6becc5f A+7
[username@hostname remote-git]$ git rebase -i HEAD~3
[detached HEAD d3a7cd6] 1 through 3 added to the end
 Date: Thu Jan 9 01:10:54 2025 +0530
 1 file changed, 3 insertions(+)
Successfully rebased and updated refs/heads/trunk.

[username@hostname remote-git]$ git log --oneline -6
d3a7cd6 (HEAD -> trunk) 1 through 3 added to the end
2bd040b A+10
412dc0f merged the ours A+8
6becc5f A+7
c1cd86f A+8
aa92237 A+6
[username@hostname remote-git]$
```

we chaged history here 
squashed the entire stuff
use force for other cases

# 25. Searching Git Logs.mp4

In this method we will grep the changes for only certain files and not the entire logs, pretty good huh!
ja, richtig

[username@hostname git-bisect]$ git log --grep foo
[username@hostname git-bisect]$ git log -p -- src/index.js

```
[username@hostname git-bisect]$ npm i

added 75 packages, and audited 76 packages in 39s

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30029ms
   × foo 30028ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  02:21:58
   Duration  30.27s (transform 16ms, setup 0ms, collect 11ms, tests 30.03s, environment 0ms, prepare 51ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ nvim .
[username@hostname git-bisect]$ man git-log
[username@hostname git-bisect]$ git log --grep foo
commit 46dd67a482e1c44f062af23b45a76338becefd4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:17 2024 -0700

    secret? is was not about foo

commit f3a06f6a08fa724834bb66a8fe3b3f58f6c4f03a
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:12 2024 -0700

    if this isnt about foo then what the hell am i doing here?

commit 8bf2c770010f2d7f86572ab70433089f1cfd548f
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:39 2024 -0700

    how do you foo?

commit 972fa2ab45e5041a1fe8c95f31b520bc62d7af85
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:31 2024 -0700

    this commit is certainly not about foo

commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications
[username@hostname git-bisect]$ git log --grep foo -p
commit 46dd67a482e1c44f062af23b45a76338becefd4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:17 2024 -0700

    secret? is was not about foo

diff --git a/README.md b/README.md
index 78aee2f..8379ffc 100644
--- a/README.md
+++ b/README.md
@@ -15,3 +15,4 @@ L
 M
 N
 if this isnt about foo then what the hell am i doing here?
+secret? is was not about foo

commit f3a06f6a08fa724834bb66a8fe3b3f58f6c4f03a
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:12 2024 -0700

    if this isnt about foo then what the hell am i doing here?

diff --git a/README.md b/README.md
index 99fd4f9..78aee2f 100644
--- a/README.md
+++ b/README.md
@@ -14,3 +14,4 @@ K
 L
 M
 N
+if this isnt about foo then what the hell am i doing here?

commit 8bf2c770010f2d7f86572ab70433089f1cfd548f
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:39 2024 -0700

    how do you foo?

diff --git a/README.md b/README.md
index 056a442..b9058b2 100644
--- a/README.md
+++ b/README.md
@@ -8,3 +8,4 @@ G
 H
 I
 this commit is certainly not about foo
+how do you foo?

commit 972fa2ab45e5041a1fe8c95f31b520bc62d7af85
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:31 2024 -0700

    this commit is certainly not about foo

diff --git a/README.md b/README.md
index 00b7376..056a442 100644
--- a/README.md
+++ b/README.md
@@ -7,3 +7,4 @@ F
 G
 H
 I
+this commit is certainly not about foo

commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

diff --git a/src/index.js b/src/index.js
index 4f35883..e8052cc 100644
--- a/src/index.js
+++ b/src/index.js
@@ -4,5 +4,5 @@
  * @return {number}
  */
 export function foo(x) {
-    return x * 69;
+    return x * 70;
 }
[username@hostname git-bisect]$ git log -p -- src/index.js
commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

diff --git a/src/index.js b/src/index.js
index 4f35883..e8052cc 100644
--- a/src/index.js
+++ b/src/index.js
@@ -4,5 +4,5 @@
  * @return {number}
  */
 export function foo(x) {
-    return x * 69;
+    return x * 70;
 }

commit b56ed570fedc6eff3d2ae1674b7ba8fa21690c4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:18:18 2024 -0700

    feat: initial commit and veyr working test.

diff --git a/src/index.js b/src/index.js
new file mode 100644
index 0000000..4f35883
--- /dev/null
+++ b/src/index.js
@@ -0,0 +1,8 @@
+
+/**
+ * @param {number} x
+ * @return {number}
+ */
+export function foo(x) {
+    return x * 69;
+}
[username@hostname git-bisect]$


```

# 26. Bisect.mp4

read bisect concept from internet again but I have just for revision.

O(log n)

Steps or Basics of Bisect

1. start git bisect `git bisect start`
2. set the known bad commit `git bisect bad`, uses the current one
3. set the known good commit `git bisect good <commit>`
4. test
5. git bisect `<good | bad>` depending on how the test runs
6. goto 4 until git tells you the commit.

simply saying, this is like boolean search of if we are looking for right commit then we select the failing one as bad and the one which is running successfully as good and we move towards the commit that started to fail.

like commit: 1st 2nd 3rd 4th 5th 6th 7th 8th 
8th failing 
1st wokrking 
then bisect it then it will run the 4th or 5th and if still failing then 
set it bad then it will next move towards <- left towards 1st if its good then failing one must be towards -> right.
This is simple boolean search.

```
gpt

Here's a corrected version of your explanation with improved grammar:

---

### Bisect Concept (O(log n))

**Steps or Basics of Bisect:**

1. Start git bisect: `git bisect start`
2. Set the known bad commit: `git bisect bad` (this uses the current commit)
3. Set the known good commit: `git bisect good <commit>`
4. Test the code to check for the issue
5. Depending on the test result, run `git bisect <good | bad>`
6. Repeat step 4 until Git tells you the commit that introduced the issue.

In simple terms, bisecting is like performing a binary search to find the commit where a bug or issue was introduced. If you know that a certain commit is good and another one is bad, Git will start testing commits in the middle. It narrows down the search by repeatedly dividing the range of commits and selecting the commit that is more likely to be the cause of the issue.

For example, if you have a sequence of commits:

```
1st 2nd 3rd 4th 5th 6th 7th 8th
```

- The 8th commit is failing, and the 1st commit is working. 
- Git will first test the middle commit, say the 4th or 5th. 
- If it still fails, you mark it as "bad," and Git will move towards earlier commits.
- If the middle commit is good, Git moves towards later commits.

This approach continues, similar to a binary search, to efficiently locate the problematic commit.

---

### Improved Explanation with Proper Flow:

Git Bisect is a powerful tool used to identify the specific commit that introduced a bug. It works by performing a binary search over the commit history, which makes it much more efficient than manually testing each commit.

Here’s how it works:

1. **Start Bisecting:** You begin by initializing the bisect process with `git bisect start`.
2. **Identify a Known Bad Commit:** Mark the current commit as "bad" using `git bisect bad`. This tells Git that the issue exists in this commit.
3. **Identify a Known Good Commit:** Mark a previous commit as "good" by using `git bisect good <commit>`. This serves as a reference where the code was still working fine.
4. **Test the Code:** After marking the good and bad commits, Git will automatically checkout a commit in the middle of the range for you to test.
5. **Evaluate the Test Result:** If the test passes, mark the commit as "good" using `git bisect good`. If the test fails, mark it as "bad" using `git bisect bad`.
6. **Repeat the Process:** Git will continue narrowing down the range of commits by testing the midpoints until it isolates the specific commit that caused the issue.

This process is efficient because, like binary search, it halves the range of commits with each step. For example, if you have eight commits, Git will first test the 4th or 5th commit. Based on the result, it will move to either the earlier or later half of the commit range, progressively narrowing the search to pinpoint the exact commit where the problem was introduced.

By following this approach, you can quickly and accurately identify the commit that broke the code, saving you time and effort compared to manually testing each commit individually.
```
These are the examples, I carried out.

```
[username@hostname git-bisect]$ npm i

added 75 packages, and audited 76 packages in 39s

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30029ms
   × foo 30028ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  02:21:58
   Duration  30.27s (transform 16ms, setup 0ms, collect 11ms, tests 30.03s, environment 0ms, prepare 51ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ nvim .
[username@hostname git-bisect]$ man git-log                                                                                                                                 
[username@hostname git-bisect]$ git log --grep foo
commit 46dd67a482e1c44f062af23b45a76338becefd4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:17 2024 -0700

    secret? is was not about foo

commit f3a06f6a08fa724834bb66a8fe3b3f58f6c4f03a
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:12 2024 -0700

    if this isnt about foo then what the hell am i doing here?

commit 8bf2c770010f2d7f86572ab70433089f1cfd548f
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:39 2024 -0700

    how do you foo?

commit 972fa2ab45e5041a1fe8c95f31b520bc62d7af85
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:31 2024 -0700

    this commit is certainly not about foo

commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications
[username@hostname git-bisect]$ git log --grep foo -p
commit 46dd67a482e1c44f062af23b45a76338becefd4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:17 2024 -0700

    secret? is was not about foo

diff --git a/README.md b/README.md
index 78aee2f..8379ffc 100644
--- a/README.md
+++ b/README.md
@@ -15,3 +15,4 @@ L
 M
 N
 if this isnt about foo then what the hell am i doing here?
+secret? is was not about foo

commit f3a06f6a08fa724834bb66a8fe3b3f58f6c4f03a
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:21:12 2024 -0700

    if this isnt about foo then what the hell am i doing here?

diff --git a/README.md b/README.md
index 99fd4f9..78aee2f 100644
--- a/README.md
+++ b/README.md
@@ -14,3 +14,4 @@ K
 L
 M
 N
+if this isnt about foo then what the hell am i doing here?

commit 8bf2c770010f2d7f86572ab70433089f1cfd548f
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:39 2024 -0700

    how do you foo?

diff --git a/README.md b/README.md
index 056a442..b9058b2 100644
--- a/README.md
+++ b/README.md
@@ -8,3 +8,4 @@ G
 H
 I
 this commit is certainly not about foo
+how do you foo?

commit 972fa2ab45e5041a1fe8c95f31b520bc62d7af85
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:31 2024 -0700

    this commit is certainly not about foo

diff --git a/README.md b/README.md
index 00b7376..056a442 100644
--- a/README.md
+++ b/README.md
@@ -7,3 +7,4 @@ F
 G
 H
 I
+this commit is certainly not about foo

commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

diff --git a/src/index.js b/src/index.js
index 4f35883..e8052cc 100644
--- a/src/index.js
+++ b/src/index.js
@@ -4,5 +4,5 @@
  * @return {number}
  */
 export function foo(x) {
-    return x * 69;
+    return x * 70;
 }
[username@hostname git-bisect]$ git log -p -- src/index.js
commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

diff --git a/src/index.js b/src/index.js
index 4f35883..e8052cc 100644
--- a/src/index.js
+++ b/src/index.js
@@ -4,5 +4,5 @@
  * @return {number}
  */
 export function foo(x) {
-    return x * 69;
+    return x * 70;
 }

commit b56ed570fedc6eff3d2ae1674b7ba8fa21690c4c
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:18:18 2024 -0700

    feat: initial commit and veyr working test.

diff --git a/src/index.js b/src/index.js
new file mode 100644
index 0000000..4f35883
--- /dev/null
+++ b/src/index.js
@@ -0,0 +1,8 @@
+
+/**
+ * @param {number} x
+ * @return {number}
+ */
+export function foo(x) {
+    return x * 69;
+}
[username@hostname git-bisect]$ git bisect sart
You need to start by "git bisect start"

Do you want me to do it for you [Y/n]? ^C
[username@hostname git-bisect]$ git bisect start
status: waiting for both good and bad commits
[username@hostname git-bisect]$ git test
git: 'test' is not a git command. See 'git --help'.

The most similar command is
        reset
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30027ms
   × foo 30026ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:00:19
   Duration  30.26s (transform 14ms, setup 0ms, collect 9ms, tests 30.03s, environment 0ms, prepare 52ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect bad
status: waiting for good commit(s), bad commit known
[username@hostname git-bisect]$ git log --oneline
e0d228e (HEAD -> master, origin/master, origin/HEAD) S
52b1f63 R
56bf073 Q
9ba8ce3 P
37d97f2 O
46dd67a secret? is was not about foo
f3a06f6 if this isnt about foo then what the hell am i doing here?
afb5df7 N
373b713 M
a7071ea L
6869ecc K
7b2b4fa J
8bf2c77 how do you foo?
972fa2a this commit is certainly not about foo
3798398 feat: altered foo to meet new specifications
eb86740 I
7e706d5 H
22aa141 G
0562cd7 F
e1aaa8b E
f1ff917 D
8a5d684 C
3ff3a2d B
f443d50 A
b56ed57 feat: initial commit and veyr working test.
[username@hostname git-bisect]$ git log -p -- src/index.js ^C
[username@hostname git-bisect]$ git bisect good b56ed57 f
error: Bad rev input: f
[username@hostname git-bisect]$ ^C
[username@hostname git-bisect]$ git bisect good b56ed57
Bisecting: 11 revisions left to test after this (roughly 4 steps)
[8bf2c770010f2d7f86572ab70433089f1cfd548f] how do you foo?
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30012ms
   × foo 30011ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:02:17
   Duration  30.26s (transform 15ms, setup 0ms, collect 10ms, tests 30.01s, environment 0ms, prepare 51ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect bad
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[0562cd710d40d23b5928747a45d71d2a76443752] F
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ✓ src/index.spec.js (1) 30021ms
   ✓ foo 30021ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  03:02:55
   Duration  30.26s (transform 15ms, setup 0ms, collect 9ms, tests 30.02s, environment 0ms, prepare 51ms)


 PASS  Waiting for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect good
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[eb867402c2e4678887c8aa322c0da3ef54851f7c] I
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ✓ src/index.spec.js (1) 30011ms
   ✓ foo 30010ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  03:03:37
   Duration  30.25s (transform 16ms, setup 0ms, collect 10ms, tests 30.01s, environment 0ms, prepare 82ms)


 PASS  Waiting for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect good
Bisecting: 0 revisions left to test after this (roughly 1 step)
[972fa2ab45e5041a1fe8c95f31b520bc62d7af85] this commit is certainly not about foo
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30028ms
   × foo 30027ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:04:22
   Duration  30.26s (transform 17ms, setup 0ms, collect 9ms, tests 30.03s, environment 0ms, prepare 65ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect bad
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[3798398f377cd1722284ff30b211e3b66e218738] feat: altered foo to meet new specifications
[username@hostname git-bisect]$ npm run test

> git-bisect@1.0.0 test
> vitest


 DEV  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30028ms
   × foo 30028ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:05:33
   Duration  30.27s (transform 15ms, setup 0ms, collect 10ms, tests 30.03s, environment 0ms, prepare 52ms)


 FAIL  Tests failed. Watching for file changes...
       press h to show help, press q to quit
[username@hostname git-bisect]$ git bisect bad
3798398f377cd1722284ff30b211e3b66e218738 is the first bad commit
commit 3798398f377cd1722284ff30b211e3b66e218738 (HEAD)
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

 src/index.js | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname git-bisect]$ git status
HEAD detached at 3798398
You are currently bisecting, started from branch 'master'.
  (use "git bisect reset" to get back to the original branch)

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        package-lock.json

nothing added to commit but untracked files present (use "git add" to track)
[username@hostname git-bisect]$
[username@hostname git-bisect]$
[username@hostname git-bisect]$
[username@hostname git-bisect]$
[username@hostname git-bisect]$ NOW AUTOMATE THE GIT BISECT
-bash: NOW: command not found
[username@hostname git-bisect]$ git bisect reset
Previous HEAD position was 3798398 feat: altered foo to meet new specifications
Switched to branch 'master'
Your branch is up to date with 'origin/master'.
[username@hostname git-bisect]$ git bisect start
status: waiting for both good and bad commits
(failed reverse-i-search)`bad': git re^Cse -i HEAD~3
[username@hostname git-bisect]$ git bisect bad
status: waiting for good commit(s), bad commit known
[username@hostname git-bisect]$ git bisect g ^Cd
[username@hostname git-bisect]$ git bisect good b56ed57
Bisecting: 11 revisions left to test after this (roughly 4 steps)
[8bf2c770010f2d7f86572ab70433089f1cfd548f] how do you foo?
[username@hostname git-bisect]$ git bisect run ./node_modules/.bin/vite
vite       vite-node  vitest
[username@hostname git-bisect]$ git bisect run ./node_modules/.bin/vite
vite       vite-node  vitest
[username@hostname git-bisect]$ git bisect run ./node_modules/.bin/vitest --run
running './node_modules/.bin/vitest' '--run'

 RUN  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30024ms
   × foo 30024ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:10:17
   Duration  30.33s (transform 29ms, setup 0ms, collect 10ms, tests 30.02s, environment 0ms, prepare 72ms)

Bisecting: 5 revisions left to test after this (roughly 3 steps)
[0562cd710d40d23b5928747a45d71d2a76443752] F
running './node_modules/.bin/vitest' '--run'

 RUN  v1.6.0 /home/cesium/git-bisect

 ✓ src/index.spec.js (1) 30008ms
   ✓ foo 30007ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  03:10:48
   Duration  30.32s (transform 55ms, setup 1ms, collect 10ms, tests 30.01s, environment 0ms, prepare 122ms)

Bisecting: 2 revisions left to test after this (roughly 2 steps)
[eb867402c2e4678887c8aa322c0da3ef54851f7c] I
running './node_modules/.bin/vitest' '--run'

 RUN  v1.6.0 /home/cesium/git-bisect

 ✓ src/index.spec.js (1) 30023ms
   ✓ foo 30023ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  03:11:18
   Duration  30.36s (transform 17ms, setup 0ms, collect 10ms, tests 30.02s, environment 0ms, prepare 56ms)

Bisecting: 0 revisions left to test after this (roughly 1 step)
[972fa2ab45e5041a1fe8c95f31b520bc62d7af85] this commit is certainly not about foo
running './node_modules/.bin/vitest' '--run'

 RUN  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30027ms
   × foo 30026ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:11:49
   Duration  30.35s (transform 61ms, setup 0ms, collect 11ms, tests 30.03s, environment 0ms, prepare 132ms)

Bisecting: 0 revisions left to test after this (roughly 0 steps)
[3798398f377cd1722284ff30b211e3b66e218738] feat: altered foo to meet new specifications
running './node_modules/.bin/vitest' '--run'

 RUN  v1.6.0 /home/cesium/git-bisect

 ❯ src/index.spec.js (1) 30028ms
   × foo 30027ms

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/index.spec.js > foo
AssertionError: expected 140 to deeply equal 138

- Expected
+ Received

- 138
+ 140

 ❯ src/index.spec.js:6:20
      4| test("foo", async () => {
      5|     await (new Promise(res => setTimeout(res, 30000)));
      6|     expect(foo(2)).toEqual(2 * 69);
       |                    ^
      7| }, 35000);
      8|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  03:12:20
   Duration  30.39s (transform 25ms, setup 0ms, collect 11ms, tests 30.03s, environment 0ms, prepare 109ms)

3798398f377cd1722284ff30b211e3b66e218738 is the first bad commit
commit 3798398f377cd1722284ff30b211e3b66e218738
Author: mpaulson <mpaulson@netflix.com>
Date:   Fri Feb 16 13:20:16 2024 -0700

    feat: altered foo to meet new specifications

 src/index.js | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
bisect found first bad commit
[username@hostname git-bisect]$

```

# 27. Revert.mp4

we don't remove the commit from history or alter the history simple the contents that was changed in revert commit simply 
turned , like matter changed to anti matter.

+1 turn to -1 simple 

and we commit the latest changes if need in front/HEAD

```
[username@hostname hello-git]$ git log --grep E
commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:39:23 2024 +0530

    added A in README.md
[username@hostname hello-git]$ git log --grep E -p
commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

diff --git a/README.md b/README.md
index d3045e2..4c12719 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+1
 D
 E

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

diff --git a/README.md b/README.md
index d3045e2..d34c9c8 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+2
 D
 E

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

diff --git a/README.md b/README.md
index b2f0a9a..d3045e2 100644
--- a/README.md
+++ b/README.md
@@ -1,2 +1,3 @@
 A
 D
+E

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

diff --git a/README.md b/README.md
index f70f10e..b2f0a9a 100644
--- a/README.md
+++ b/README.md
@@ -1 +1,2 @@
 A
+D

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:39:23 2024 +0530

    added A in README.md

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..f70f10e
--- /dev/null
+++ b/README.md
@@ -0,0 +1 @@
+A
[username@hostname hello-git]$  echo "REVERTING THE COMMIT WITH SHA  7a34d430953eb64b3d6666a04b50513937928efe"
REVERTING THE COMMIT WITH SHA  7a34d430953eb64b3d6666a04b50513937928efe
[username@hostname hello-git]$ git revert  7a34d430953eb64b3d6666a04b50513937928efe
Auto-merging README.md
[trunk d70762c] Revert "added E in README.md"
 1 file changed, 1 deletion(-)
[username@hostname hello-git]$ git log --grep E
commit d70762c4ca93c34b1ea63a2a358f1e091f464fcf (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Thu Jan 9 03:23:45 2025 +0530

    Revert "added E in README.md"

    This reverts commit 7a34d430953eb64b3d6666a04b50513937928efe.

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
[username@hostname hello-git]$ git log --grep E -p
commit d70762c4ca93c34b1ea63a2a358f1e091f464fcf (HEAD -> trunk)
Author: cesium <cesium@chernobyl.com>
Date:   Thu Jan 9 03:23:45 2025 +0530

    Revert "added E in README.md"

    This reverts commit 7a34d430953eb64b3d6666a04b50513937928efe.

diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

diff --git a/README.md b/README.md
index d3045e2..4c12719 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+1
 D
 E

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

diff --git a/README.md b/README.md
index d3045e2..d34c9c8 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+2
 D
 E

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

diff --git a/README.md b/README.md
index b2f0a9a..d3045e2 100644
--- a/README.md
+++ b/README.md
@@ -1,2 +1,3 @@
 A
 D
+E
[username@hostname hello-git]$ git revert  50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
error: could not revert 50dfab7... Added A+1 in README.md
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config advice.mergeConflict false"
[username@hostname hello-git]$ git status
On branch trunk
You are currently reverting commit 50dfab7.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ cat README.md
<<<<<<< HEAD
A+9
NEWLINE
=======
A
>>>>>>> parent of 50dfab7 (Added A+1 in README.md)
D
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ git status
On branch trunk
You are currently reverting commit 50dfab7.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ cat README.md
A
NEWLINE
D
[username@hostname hello-git]$ git diff
diff --cc README.md
index be27ecf,d3045e2..0000000
--- a/README.md
+++ b/README.md
@@@ -1,3 -1,3 +1,3 @@@
- A+9
+ A
 +NEWLINE
  D
 -E
[username@hostname hello-git]$ git add .
[username@hostname hello-git]$  git add .; git commit -m "reverted to A";
[trunk d766881] reverted to A
 1 file changed, 1 insertion(+), 1 deletion(-)
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git diff^C
[username@hostname hello-git]$ git log --grep E -p
commit d70762c4ca93c34b1ea63a2a358f1e091f464fcf
Author: cesium <cesium@chernobyl.com>
Date:   Thu Jan 9 03:23:45 2025 +0530

    Revert "added E in README.md"

    This reverts commit 7a34d430953eb64b3d6666a04b50513937928efe.

diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

diff --git a/README.md b/README.md
index d3045e2..4c12719 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+1
 D
 E

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

diff --git a/README.md b/README.md
index d3045e2..d34c9c8 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+2
 D
 E

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

diff --git a/README.md b/README.md
index b2f0a9a..d3045e2 100644
--- a/README.md
+++ b/README.md
@@ -1,2 +1,3 @@
 A
 D
+E

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

diff --git a/README.md b/README.md
index f70f10e..b2f0a9a 100644
--- a/README.md
+++ b/README.md
@@ -1 +1,2 @@
 A
+D

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:39:23 2024 +0530

    added A in README.md

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..f70f10e
--- /dev/null
+++ b/README.md
@@ -0,0 +1 @@
+A
[username@hostname hello-git]$ git log --grep E
commit d70762c4ca93c34b1ea63a2a358f1e091f464fcf
Author: cesium <cesium@chernobyl.com>
Date:   Thu Jan 9 03:23:45 2025 +0530

    Revert "added E in README.md"

    This reverts commit 7a34d430953eb64b3d6666a04b50513937928efe.

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
[username@hostname hello-git]$ git log --grep ^C
[username@hostname hello-git]$ git log --oneonline
fatal: unrecognized argument: --oneonline
[username@hostname hello-git]$ git log --oneline
d766881 (HEAD -> trunk) reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
6becc5f A+7
c1cd86f A+8
aa92237 A+6
cbfe0c9 changes from remote for rebase conflict
677ed7c Added rerere in new
6d4dc9c Added NEWLINE
11bdc28 A+5
142df15 changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
161ab6e Added no conflict in bar.md
9f24204 Merge branch 'trunk' of ../hello-git into trunk
e08f023 Added no conflict in bar.md
c3f151c Merge branch 'trunk' of ../hello-git into trunk
59f0cd7 Added no conflick in bar.md
3afc0f8 merged in upstream
50dfab7 Added A+1 in README.md
4bab54f Added A+2 in README.md
291f00f cleaned again
2a959fa added A+2
3831d52 added A+1
d455508 cleaned
6b1c6a2 added A+11
df8bb15 added A+2
7ec20aa added commmit for another changes from stash
4267c1b added commmit for changes from stash
4ca7201 ----------------
a0738be don't know about this commit
759df93 A remote change
a51b61c added new i n new.md
bac9f79 baz file added
7b9771c added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
c48da92 added A in README.md
[username@hostname hello-git]$ nvim .^C
[username@hostname hello-git]$ git log --grep E -p
commit d70762c4ca93c34b1ea63a2a358f1e091f464fcf
Author: cesium <cesium@chernobyl.com>
Date:   Thu Jan 9 03:23:45 2025 +0530

    Revert "added E in README.md"

    This reverts commit 7a34d430953eb64b3d6666a04b50513937928efe.

diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E

commit 6d4dc9c19d23cbc54fc3f2185704acc21233c9c9
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 06:36:50 2025 +0530

    Added NEWLINE

diff --git a/README.md b/README.md
index d88127d..3bc4f04 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 A+5
+NEWLINE
 D
 E

commit 50dfab7775da5eb75c96636bfb8115e99f9ccf4a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:52 2025 +0530

    Added A+1 in README.md

diff --git a/README.md b/README.md
index d3045e2..4c12719 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+1
 D
 E

commit 4bab54f98d874c28bb20869f04fad890a16a395a
Author: cesium <cesium@chernobyl.com>
Date:   Wed Jan 8 03:40:27 2025 +0530

    Added A+2 in README.md

diff --git a/README.md b/README.md
index d3045e2..d34c9c8 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A
+A+2
 D
 E

commit 7a34d430953eb64b3d6666a04b50513937928efe
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:48 2024 +0530

    added E in README.md

diff --git a/README.md b/README.md
index b2f0a9a..d3045e2 100644
--- a/README.md
+++ b/README.md
@@ -1,2 +1,3 @@
 A
 D
+E

commit e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 17:45:18 2024 +0530

    added D in README.md

diff --git a/README.md b/README.md
index f70f10e..b2f0a9a 100644
--- a/README.md
+++ b/README.md
@@ -1 +1,2 @@
 A
+D

commit c48da927dc37172446aa5b6450db9bbdcb55f03b
Author: uranium <uranium@chernobyl>
Date:   Fri Dec 27 16:39:23 2024 +0530

    added A in README.md

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..f70f10e
--- /dev/null
+++ b/README.md
@@ -0,0 +1 @@
+A
[username@hostname hello-git]$ git revert  e55d51fc584f8ed4cdf7c0c10709ae17578239b1
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
error: could not revert e55d51f... added D in README.md
hint: After resolving the conflicts, mark them with
hint: "git add/rm <pathspec>", then run
hint: "git revert --continue".
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config advice.mergeConflict false"
[username@hostname hello-git]$ git status
On branch trunk
You are currently reverting commit e55d51f.
  (fix conflicts and run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ cat README.md
A
<<<<<<< HEAD
NEWLINE
D
=======
>>>>>>> parent of e55d51f (added D in README.md)
[username@hostname hello-git]$ git diff
diff --cc README.md
index 4fb6aac,f70f10e..0000000
mode 100755,100644..100755
--- a/README.md
+++ b/README.md
@@@ -1,3 -1,1 +1,6 @@@
  A
++<<<<<<< HEAD
 +NEWLINE
 +D
++=======
++>>>>>>> parent of e55d51f (added D in README.md)
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$ git diff
diff --cc README.md
index 4fb6aac,f70f10e..0000000
mode 100755,100644..100755
--- a/README.md
+++ b/README.md
@@@ -1,3 -1,1 +1,2 @@@
  A
 +NEWLINE
- D
[username@hostname hello-git]$  git add .
[username@hostname hello-git]$ git status
On branch trunk
You are currently reverting commit e55d51f.
  (all conflicts fixed: run "git revert --continue")
  (use "git revert --skip" to skip this patch)
  (use "git revert --abort" to cancel the revert operation)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[username@hostname hello-git]$  git add .; git commit -m "reverted the D";
[trunk 317fc23] reverted the D
 1 file changed, 1 deletion(-)
[username@hostname hello-git]$ git log --oneline
317fc23 (HEAD -> trunk) reverted the D
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
6becc5f A+7
c1cd86f A+8
aa92237 A+6
cbfe0c9 changes from remote for rebase conflict
677ed7c Added rerere in new
6d4dc9c Added NEWLINE
11bdc28 A+5
142df15 changes from hello for rebase conflict
1411245 Merge branch 'trunk' of ../hello-git into trunk
161ab6e Added no conflict in bar.md
9f24204 Merge branch 'trunk' of ../hello-git into trunk
e08f023 Added no conflict in bar.md
c3f151c Merge branch 'trunk' of ../hello-git into trunk
59f0cd7 Added no conflick in bar.md
3afc0f8 merged in upstream
50dfab7 Added A+1 in README.md
4bab54f Added A+2 in README.md
291f00f cleaned again
2a959fa added A+2
3831d52 added A+1
d455508 cleaned
6b1c6a2 added A+11
df8bb15 added A+2
7ec20aa added commmit for another changes from stash
4267c1b added commmit for changes from stash
4ca7201 ----------------
a0738be don't know about this commit
759df93 A remote change
a51b61c added new i n new.md
bac9f79 baz file added
7b9771c added Y in bar.md
0c05104 added X in bar.md
7a34d43 added E in README.md
e55d51f added D in README.md
[username@hostname hello-git]$ git log --oneline -p
317fc23 (HEAD -> trunk) reverted the D
diff --git a/README.md b/README.md
index 4fb6aac..9174612 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,2 @@
 A
 NEWLINE
-D
d766881 reverted to A
diff --git a/README.md b/README.md
index be27ecf..4fb6aac 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+9
+A
 NEWLINE
 D
d70762c Revert "added E in README.md"
diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E
6de00e3 A+9
diff --git a/README.md b/README.md
index 852c103..3fdf7d6 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,4 @@
-A+8
+A+9
 NEWLINE
 D
[username@hostname hello-git]$

```

# 28. Reset.mp4

SOFT

This changes history  

reset --soft move the branch and head back one commit
$ git reset --soft HEAD~1

if we continue to edit our previous commit.We have two options.

1. we could make changes and use `commit -amend`. If you are not familiar with `git commit --ammend` it allows you to meld the current staged changes into the previous commit and edit the message.

2. we could use `git reset --soft HEAD~1` to move `trunk` back one commit and alter the index and worktree to match the contents of the commit.

Both operation will change the sha since we are changing the graph fundamentally.
```

[username@hostname hello-git]$ git log --oneline -6
317fc23 (HEAD -> trunk) reverted the D
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
6becc5f A+7
[username@hostname hello-git]$ git log --oneline -3 -p
317fc23 (HEAD -> trunk) reverted the D
diff --git a/README.md b/README.md
index 4fb6aac..9174612 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,2 @@
 A
 NEWLINE
-D
d766881 reverted to A
diff --git a/README.md b/README.md
index be27ecf..4fb6aac 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+9
+A
 NEWLINE
 D
d70762c Revert "added E in README.md"
diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E
[username@hostname hello-git]$ git reset --soft HEAD~1
[username@hostname hello-git]$ git log --oneline -6
d766881 (HEAD -> trunk) reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
6becc5f A+7
c1cd86f A+8
[username@hostname hello-git]$ git log --oneline -3 -p
d766881 (HEAD -> trunk) reverted to A
diff --git a/README.md b/README.md
index be27ecf..4fb6aac 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+9
+A
 NEWLINE
 D
d70762c Revert "added E in README.md"
diff --git a/README.md b/README.md
index 3fdf7d6..be27ecf 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,3 @@
 A+9
 NEWLINE
 D
-E
6de00e3 A+9
diff --git a/README.md b/README.md
index 852c103..3fdf7d6 100755
--- a/README.md
+++ b/README.md
@@ -1,4 +1,4 @@
-A+8
+A+9
 NEWLINE
 D
 E
[username@hostname hello-git]$ git status
On branch trunk
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[username@hostname hello-git]$ cat README.md
A
NEWLINE
[username@hostname hello-git]$ git diff --staged
diff --git a/README.md b/README.md
index 4fb6aac..9174612 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,2 @@
 A
 NEWLINE
-D
[username@hostname hello-git]$



[username@hostname hello-git]$  git add .; git commit -m "a new sha";
[trunk 8f17361] a new sha
 1 file changed, 1 deletion(-)
[username@hostname hello-git]$ git log --oneline -6
8f17361 (HEAD -> trunk) a new sha
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
6becc5f A+7
[username@hostname hello-git]$ git log --oneline -2 -p
8f17361 (HEAD -> trunk) a new sha
diff --git a/README.md b/README.md
index 4fb6aac..9174612 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,2 @@
 A
 NEWLINE
-D
d766881 reverted to A
diff --git a/README.md b/README.md
index be27ecf..4fb6aac 100755
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
-A+9
+A
 NEWLINE
 D
[username@hostname hello-git]$ ^C
[username@hostname hello-git]$

```

in case of --soft , it move to reference but keep the changes staged.

HARD

this drop the changes to the index and worktree.
That means any work that is being tracked by git will be destroyed.


```
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ nvim .
[username@hostname hello-git]$  git status
On branch trunk
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        foo.md

no changes added to commit (use "git add" and/or "git commit -a")
[username@hostname hello-git]$ git diff
diff --git a/README.md b/README.md
index 9174612..0c7a0b1 100755
--- a/README.md
+++ b/README.md
@@ -1,2 +1,6 @@
 A
 NEWLINE
+
+
+
+A
[username@hostname hello-git]$ git cat README.md
git: 'cat' is not a git command. See 'git --help'.

The most similar commands are
        clean
        mktag
        stage
        stash
        tag
        var
[username@hostname hello-git]$ cat README.md
A
NEWLINE



A
[username@hostname hello-git]$ cat foo.md
sdasda
[username@hostname hello-git]$ git reset --hard
HEAD is now at 8f17361 a new sha
[username@hostname hello-git]$ git status
On branch trunk
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        foo.md

nothing added to commit but untracked files present (use "git add" to track)
[username@hostname hello-git]$ cat foo.md
sdasda
[username@hostname hello-git]$ git diff
[username@hostname hello-git]$ git add foo.md
[username@hostname hello-git]$ git status
On branch trunk
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   foo.md

[username@hostname hello-git]$ git reset --hard
HEAD is now at 8f17361 a new sha
[username@hostname hello-git]$ git status
On branch trunk
nothing to commit, working tree clean
[username@hostname hello-git]$ git diff
[username@hostname hello-git]$ echo "line added for reset hard" >> README.md
[username@hostname hello-git]$ cat README.md
A
NEWLINE
line added for reset hard
[username@hostname hello-git]$ git add README.md
[username@hostname hello-git]$ git log --oneline -2
8f17361 (HEAD -> trunk) a new sha
d766881 reverted to A
[username@hostname hello-git]$ git log --oneline -4
8f17361 (HEAD -> trunk) a new sha
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
[username@hostname hello-git]$ git ad README.md
git: 'ad' is not a git command. See 'git --help'.

The most similar commands are
        add
        am
[username@hostname hello-git]$ ^C
[username@hostname hello-git]$ git status
On branch trunk
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   README.md

[username@hostname hello-git]$ git commit -m "added a file for reset"
[trunk 3d61444] added a file for reset
 1 file changed, 1 insertion(+)
[username@hostname hello-git]$ git log --oneline -4
3d61444 (HEAD -> trunk) added a file for reset
8f17361 a new sha
d766881 reverted to A
d70762c Revert "added E in README.md"
[username@hostname hello-git]$   git reset --hard HEAD~1
HEAD is now at 8f17361 a new sha
[username@hostname hello-git]$ git log --oneline -4
8f17361 (HEAD -> trunk) a new sha
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
[username@hostname hello-git]$   git reset --hard HEAD~1
HEAD is now at d766881 reverted to A
[username@hostname hello-git]$ git log --oneline -4
d766881 (HEAD -> trunk) reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
[username@hostname hello-git]$
```
git reset --hard HEAD~1

there are ways to go back to the changes we removed with reset --hard using reflogs 
```
[username@hostname hello-git]$   git reset --hard HEAD~1
HEAD is now at d766881 reverted to A
[username@hostname hello-git]$ git log --oneline -4
d766881 (HEAD -> trunk) reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
412dc0f merged the ours A+8
[username@hostname hello-git]$ git reflog
d766881 (HEAD -> trunk) HEAD@{0}: reset: moving to HEAD~1
8f17361 HEAD@{1}: reset: moving to HEAD~1
3d61444 HEAD@{2}: commit: added a file for reset
8f17361 HEAD@{3}: reset: moving to HEAD
8f17361 HEAD@{4}: reset: moving to HEAD
8f17361 HEAD@{5}: commit: a new sha
d766881 (HEAD -> trunk) HEAD@{6}: reset: moving to HEAD~1
317fc23 HEAD@{7}: commit: reverted the D
d766881 (HEAD -> trunk) HEAD@{8}: commit: reverted to A
d70762c HEAD@{9}: revert: Revert "added E in README.md"
6de00e3 HEAD@{10}: reset: moving to HEAD~3
c7ff531 HEAD@{11}: commit: 3 added to the end
b5fc63f HEAD@{12}: commit: 2 added to the end
c6a7a4a HEAD@{13}: commit: 1 added to the end
6de00e3 HEAD@{14}: commit: A+9
412dc0f HEAD@{15}: checkout: moving from bar to trunk
ac0105b (bar) HEAD@{16}: checkout: moving from trunk to bar
6becc5f HEAD@{17}: commit: A+7
677ed7c HEAD@{18}: commit: Added rerere in new
6d4dc9c HEAD@{19}: reset: moving to HEAD~1
09fffa0 HEAD@{20}: commit: Added rerere change in bar
6d4dc9c HEAD@{21}: commit: Added NEWLINE
11bdc28 HEAD@{22}: commit: A+5
142df15 HEAD@{23}: commit: changes from hello for rebase conflict
1411245 HEAD@{24}: reset: moving to HEAD~1
535d4db HEAD@{25}: commit: changes from hello for rebase conflict
1411245 HEAD@{26}: checkout: moving from bar to trunk
ac0105b (bar) HEAD@{27}: checkout: moving from trunk to bar
2255860 HEAD@{28}: commit: changes from hello for rebase conflict
1411245 HEAD@{29}: checkout: moving from bar to trunk
ac0105b (bar) HEAD@{30}: checkout: moving from trunk to bar
65a35a3 HEAD@{31}: commit: change from hello-git for rebase conflict
1411245 HEAD@{32}: checkout: moving from bar to trunk
ac0105b (bar) HEAD@{33}: checkout: moving from trunk to bar
161ab6e HEAD@{34}: commit: Added no conflict in bar.md
e08f023 HEAD@{35}: commit: Added no conflict in bar.md
59f0cd7 HEAD@{36}: commit: Added no conflick in bar.md
50dfab7 HEAD@{37}: commit: Added A+1 in README.md
291f00f HEAD@{38}: checkout: moving from bar to trunk
[username@hostname hello-git]$ git checkout 317fc23
Note: switching to '317fc23'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 317fc23 reverted the D
[username@hostname hello-git]$ git brand -D trunk
git: 'brand' is not a git command. See 'git --help'.

The most similar command is
        branch
[username@hostname hello-git]$ git branch -D trunk
Deleted branch trunk (was d766881).
[username@hostname hello-git]$ git checkout -b trunk
Switched to a new branch 'trunk'
[username@hostname hello-git]$ git branch
  bar
  foo
* trunk
  trunk-merge-foo
[username@hostname hello-git]$ git ^C
[username@hostname hello-git]$ git log --oneline -4
317fc23 (HEAD -> trunk) reverted the D
d766881 reverted to A
d70762c Revert "added E in README.md"
6de00e3 A+9
[username@hostname hello-git]$

```


# 29. Worktrees.mp4

```bash
git worktree add <path>
```

The `basename` of the `path` will be used as the branch name.

```bash
git worktree list 
```

example of basename
```bash
basename /home/cesium/repo-git
#repo-git
```

# 30. Tags   Other Tools.mp4

# 31. Wrapping Up.mp4
