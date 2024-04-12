-- Kudos to https://github.com/petertriho/cmp-git/tree/main/lua/cmp_git
local M = {}

M.is_git_repo = function()
  local is_inside_git_repo = function()
    local cmd = "git rev-parse --is-inside-work-tree --is-inside-git-dir"
    return string.find(vim.fn.system(cmd), "true") ~= nil
  end

  -- buffer cwd
  local is_git_repo = M.run_in_cwd(M.get_cwd(), is_inside_git_repo)

  if not is_git_repo then
    -- fallback to cwd
    is_git_repo = is_inside_git_repo()
  end

  return is_git_repo
end

M.get_git_info = function(remotes, opts)
  opts = opts or {}

  local get_git_info = function()
    if type(remotes) == "string" then
      remotes = { remotes }
    end

    local host, owner, repo = nil, nil, nil

    if vim.bo.filetype == "octo" then
      host = require("octo.config").values.github_hostname or ""
      if host == "" then
        host = "github.com"
      end
      local filename = vim.fn.expand "%:p:h"
      owner, repo = string.match(filename, "^octo://(.+)/(.+)/.+$")
    else
      for _, remote in ipairs(remotes) do
        local cmd
        if opts.enableRemoteUrlRewrites then
          cmd = "git remote get-url " .. remote
        else
          cmd = "git config --get remote." .. remote .. ".url"
        end
        local remote_origin_url = vim.fn.system(cmd)

        if remote_origin_url ~= "" then
          local clean_remote_origin_url = remote_origin_url:gsub("%.git", ""):gsub("%s", "")

          host, owner, repo = string.match(clean_remote_origin_url, "^git@(.+):(.+)/(.+)$")

          if host == nil then
            host, owner, repo = string.match(clean_remote_origin_url, "^https?://(.+)/(.+)/(.+)$")
          end

          if host == nil then
            host, owner, repo = string.match(clean_remote_origin_url, "^ssh://git@([^:]+):*.*/(.+)/(.+)$")
          end

          if host ~= nil and owner ~= nil and repo ~= nil then
            break
          end
        end
      end
    end

    return { host = host, owner = owner, repo = repo }
  end

  -- buffer cwd
  local git_info = M.run_in_cwd(M.get_cwd(), get_git_info)

  if git_info.host == nil then
    -- fallback to cwd
    git_info = get_git_info()
  end

  return git_info
end

M.run_in_cwd = function(cwd, callback, ...)
  local args = ...
  local old_cwd = vim.fn.getcwd()

  local ok, result = pcall(function()
    vim.cmd(([[lcd %s]]):format(cwd))
    return callback(args)
  end)
  vim.cmd(([[lcd %s]]):format(old_cwd))
  if not ok then
    error(result)
  end
  return result
end

M.get_cwd = function()
  if vim.fn.getreg "%" ~= "" and vim.bo.filetype ~= "octo" then
    return vim.fn.expand "%:p:h"
  end
  return vim.fn.getcwd()
end

return M
