To release a new gem set:

1. Make sure CI is passing
2. Do a global search for `VERSION = '1.0.alpha1.<current point release>'` and replace with the next point release.
3. Add a new row to `/current-status.md` with the current data
4. Add a new file in `/release-notes` (see existing files for format)
5. Update `README.md` with last entry from `current-status.md`
6. Commit all the above. <- VERY IMPORTANT TO DO THIS BEFORE ADDING THE TAG
7. `git tag 1.0.alpha1.<new point release>`
8. `git push --tags origin edge` <- once build passes gems will be released!!!
9. Add a new release note (add release in git hub): Copy contents of the release note you created
