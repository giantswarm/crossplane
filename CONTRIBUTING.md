## Update from upstream


The original Helm chart is located at: https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane.

To update using the git-subtree method, follows this steps:

- (do this only once per cloning/setting up the repo on local drive) Set up upstream repo info:
  ```
  git remote add -f upstream-crossplane https://github.com/crossplane/crossplane.git
  ```
- Choose a tag from the upstream repo that you want to update to. Here w choose tag `v1.9.1` as an example:
  ```
  git fetch upstream-crossplane refs/tags/v1.9.1:refs/tags/v1.9.1
  ```
- Create a branch from `main` that you will use to provide (create a PR from) the upgrade
  ```
  git checkout main
  git checkout -b upgrade-to-v1.9.1
  ```
- Checkout the remote state you want to get the upgrade from (it's OK to be in detached head state here):
  ```
  git checkout v1.9.1
  ```
- Extract the chart directory in the current version to a temporary branch
  ```
  git subtree split -P cluster/charts/ -b temp-split-branch
  ```
- Switch to the branch where you want to merge the upstream changes to, merge them, and cleanup the temporary branch
  ```
  git checkout upgrade-to-v1.9.1
  git subtree merge --squash -P helm/ temp-split-branch
  git branch -D temp-split-branch
  ```
- Do any changes necessary on top of the merged update, including necessary manual work:
  - When done changing the `values.yaml` please regenerate `values.schema.yaml`
  with `helm schema-gen helm/crossplane/values.yaml > helm/crossplane/values.schema.json`
  - Update the `Chart.yaml` of the App Chart in `helm/crossplane/Chart.yaml`:
    - Update `version`, `upstreamchartVersion` and `appVersion` to the upgraded Crossplane version
  - update the CRDs that are located at: https://github.com/crossplane/crossplane/tree/master/cluster/crds.
    - Copy them over to `helm/crossplane/crd-base` and remove the `pkg.crossplane.io_` prefixes from the file names, because
    they are used as ConfigMap names by the CRD install job, and must be a [valid DNS subdomain name](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-object).

- Create a PR on github from `upgrade-to-v1.9.1` to `main`, *making sure you won't remove git's subtree info*!!! The subtree info is a a commit's comment that looks like
  ```
    git-subtree-dir: helm
    git-subtree-split: 4e15d71f2947056172bfae8f3cee149c1cb9be0d
  ```
