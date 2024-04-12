# validate-gitlab-ci

Neovim plugin that uses [Gitlab CI lint
API](https://docs.gitlab.com/ee/api/lint.html#validate-a-ci-yaml-configuration-with-a-namespace)
to validate your Gitlab CI Pipeline.


https://github.com/sbulav/validate-gitlab-ci.nvim/assets/28604639/043a421f-3b84-49ec-9588-f6f0ce4d2cb3



As `/CI/lint` endpoint is deprecated in [Gitlab
16.0](https://docs.gitlab.com/ee/update/deprecations.html?removal_milestone=16.0#post-cilint-api-endpoint-deprecated)
this plugin uses `/projects/:id/ci/lint` to validate the pipeline.

Due to this, Gitlab token is required. Owner(Group) and project are detected
automatically from the git repo.

## Prerequisites

- Neovim >= 0.6
- curl available
- yq available
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) installed
- Ensure you have `GITLAB_API_TOKEN` or `GITLAB_TOKEN` environment variable set.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
 "sbulav/validate-gitlab-ci.nvim",
 dependencies = { "nvim-lua/plenary.nvim" },
 opts = {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
 },
}
```

### [packer](https://github.com/lewis6991/pckr.nvim)

```lua
use({'sbulav/ validate-gitlab-ci.nvim', requires = { "nvim-lua/plenary.nvim" } })
```


After installation, you can create autocommand group to run validate on save:

```lua
vim.api.nvim_create_augroup("ValidateGitlabCIfiles", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        require("validate-gitlab-ci.validate-gitlab-ci").validate()
    end,
    group = "ValidateGitlabCIfiles",
    desc = "Validate Gitlab CI  files on save",
    pattern = ".gitlab-ci.yml",
})
```

Or run validation manually via command:

```
:lua require("validate-gitlab-ci.validate-gitlab-ci").validate()
```
