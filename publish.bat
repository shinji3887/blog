git add .
git commit -m "update%s"
git push origin master
hugo -d d:\static
cd d:\static
git add .
git commit -m "update%s"
git push origin master
echo "deploy complete successfully!"