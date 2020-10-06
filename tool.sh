hexo clean
sleep 1
hexo g
sleep 1
git add -A
sleep 1
git commit -m "sync"
sleep 1
git push origin zjw-dev
sleep 1
hexo d
