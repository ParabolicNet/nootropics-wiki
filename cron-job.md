check if current branch == master
if not,
  send mail
  fail

git fetch
git merge
if conflict,
  git reset --hard ORIG_HEAD
  send mail
  fail

git push || fail

done.
