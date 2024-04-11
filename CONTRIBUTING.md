[DEPRECATED]

The method below is temporarily deprecated and \*\* replaced with a more automated approach we're testing now.

## Update from upstream

The original Helm chart is located at: https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane.

Here we're using our fork of the repo, that we keep in order to make potential contributions upstream easier.

### Update the upstream fork repo

Go to the <https://github.com/giantswarm/crossplane-upstream> repo, update it with the most recent upstream changes:

```
# if you're checking out the repo for the first time, set up remote and fetch all changes
git remote add -f --tags upstream https://github.com/crossplane/crossplane.git

# if you already have the remote
git fetch --tags upstream

# make sure to keep at least 'main' branches in sync (also, any other branch you might want to use, like release branches)
git merge upstream/master master
git push origin master
git push --tags

# (optional) check that the tag you want to upgrade to is present in the repo
git tag -l
```

### Update our chart repo (this one)

To update using the git-subtree method, follows this steps:

- (do this only once per cloning/setting up the repo on local drive) Set up upstream repo info:
  ```
  git remote add upstream-crossplane https://github.com/giantswarm/crossplane-upstream.git
  ```
- Choose a tag from the upstream repo that you want to update to. Here w choose tag `v1.10.1` as an example:
  ```
  git fetch --no-tags upstream-crossplane refs/tags/v1.10.1:refs/tags/upstream-v1.10.1
  ```
- Create a branch from `main` that you will use to provide (create a PR from) the upgrade
  ```
  git checkout main
  git checkout -b upgrade-to-v1.10.1
  ```
- Checkout the remote state you want to get the upgrade from (it's OK to be in detached head state here):
  ```
  git checkout upstream-v1.10.1
  ```
- Extract the chart directory in the current version to a temporary branch and CRDs directory to another one
  ```
  git subtree split -P cluster/charts/ -b temp-split-branch
  git subtree split -P cluster/crds -b temp-split-branch-crds
  ```
- Switch to the branch where you want to merge the upstream changes to, merge them, and cleanup the temporary branches (optional, but recommended: add notes to the merge commits)
  ```
  git checkout upgrade-to-v1.10.1
  git subtree merge --squash -P helm/ temp-split-branch
  git notes add -m "updated to crossplane tag v1.10.1 - helm chart"
  git subtree merge --squash -P helm/crossplane/crd-base temp-split-branch-crds
  git notes add -m "updated to crossplane tag v1.10.1 - CRDs"
  git branch -D temp-split-branch
  git branch -D temp-split-branch-crds
  # optional: you might want to delete your local tag to upstream
  git tag -d upstream-v1.10.1
  ```
- Do any changes necessary on top of the merged update, including necessary manual work:

  - When done changing the `values.yaml` (either from upstream or manually), please regenerate `values.schema.yaml`
    with `helm schema-gen helm/crossplane/values.yaml > helm/crossplane/values.schema.json`
  - Update the `Chart.yaml` of the App Chart in `helm/crossplane/Chart.yaml`:
    - Update `version`, `upstreamchartVersion` and `appVersion` to the upgraded Crossplane version
  - Update the `templates/_version_helper.tpl` and set manually the correct image version there (ie. "v1.10.1")
  - Check and update providers' versions defined in `values.yaml` - update them if there are new releases

- Create a PR on github from `upgrade-to-v1.10.1` to `main`, _making sure you won't remove git's subtree info_!!! The subtree info is a a commit's comment that looks like
  ```
    git-subtree-dir: helm
    git-subtree-split: 4e15d71f2947056172bfae8f3cee149c1cb9be0d
  ```
  - The above means that you _cannot_ do a squash PR with commit message arbitrarly edited/removed. The recommended (for visibility) way
    is to create a merge commit PR, where there are only 3 commits present: 'subtree merge's for chart and CRDs and all your
    manual changes performed on top squashed to 1 commit

### IMPORTANT

In case you ever experience something like below upon executing the `git subtree merge --squash -P helm/ temp-split-branch`:

```text
fatal: could not rev-parse split hash e0fa0bf09594c6643eaa8b2b77bc8365178d0b74 from commit 52a4848f36c5365b6b335d036fcc9819cff9bfd3
hint: hash might be a tag, try fetching it from the subtree repository:
hint:    git fetch <subtree-repository> e0fa0bf09594c6643eaa8b2b77bc8365178d0b74
```

it most probably means that the git history of the upstream project has changed, and hence some of commits' SHAs, and now when the `git subtree split -P cluster/charts/ -b temp-split-branch` is executed, the subtree create the branch with inconsistent history in comparison to what was known to the subtree before, for the `e0fa0bf09594c6643eaa8b2b77bc8365178d0b74` from the example above no longer exists.

To get out of this situation, you need to fetch the tag that has previously been used to create a split branch, then you need to use it to split another branch that will have the old git history, and then you can get back to the current `temp-split-branch` branch and proceed as usual. For Git Subtree it is enough to have the old commit under local git storage to work, it does not have to exist in the `temp-split-branch` history.

So the rough steps are as follow:

```text
# fetch previous tag:
git fetch --no-tags upstream-crossplane refs/tags/v1.9.1:refs/tags/upstream-v1.9.1

# checkout to old upstream
git checkout upstream-v1.9.1

# extract previous changes and history
git subtree split -P cluster/charts/ -b temp-split-branch-old

# get back to the upgrade branch
git checkout upgrade-to-v1.10.1

# proceed with the update
git subtree merge --squash -P helm/ temp-split-branch
```
