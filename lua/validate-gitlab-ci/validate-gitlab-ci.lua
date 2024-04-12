local curl = require "plenary.curl"
local F = require "plenary.functional"
local utils = require "validate-gitlab-ci.utils"

local token = os.getenv "GITLAB_API_TOKEN" or os.getenv "GITLAB_TOKEN"
local namespace_id = vim.api.nvim_create_namespace "validate-gitlab-ci"
local validated_msg = "Gitlab pipeline successfully validated."
local unauthorized_msg = "ERROR 401 Unauthorized"
local not_found_msg = "ERROR 404 Not Found"

local function get_payload(file_path)
  local exists = vim.fn.filereadable(file_path)
  if exists == 0 then
    vim.notify("Error: File does not exist", vim.log.levels.ERROR)
    return
  end
  local cmd = string.format("cat %s | yq -j -e", file_path)
  local json_content = vim.fn.system(cmd)

  local payload = {
    content = json_content,
  }
  return vim.fn.json_encode(payload)
end

local function curl_callback(response)
  local status = response.status
  local body = response.body
  if status ~= 200 then
    if status == 401 then
      vim.notify(unauthorized_msg, vim.log.levels.INFO)
    elseif status == 404 then
      vim.notify(not_found_msg, vim.log.levels.INFO)
    else
      body = body:gsub("%s+", " ")
      vim.notify("Error: " .. status .. " " .. body, vim.log.levels.ERROR)
    end
    return
  end

  if body == nil or body == "" then
    vim.notify("Error: no body", vim.log.levels.ERROR)
    return
  end

  vim.schedule_wrap(function(msg)
    local json = vim.fn.json_decode(msg)
    if json.valid then
      vim.diagnostic.reset(namespace_id, 0)
      vim.notify(validated_msg, vim.log.levels.INFO)
    else
      -- Set all diag messages on first line as Gitlab don't support Line errors
      local diag = {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = 0,
        end_lnum = 0,
        col = 0,
        end_col = 0,
        severity = vim.diagnostic.severity.ERROR,
        message = F.join(json.errors, "\n"),
        source = "gitlab-ci linter",
      }
      vim.diagnostic.set(namespace_id, vim.api.nvim_get_current_buf(), { diag })
    end
  end)(body)
end

local function validate_job()
  local remotes = { "upstream", "origin" }
  if not utils.is_git_repo() then
    vim.notify("Error: Unable to get repository information, not in git?", vim.log.levels.ERROR)
    return
  end

  local git_info = utils.get_git_info(remotes)
  local url = "https://"
    .. git_info.host
    .. "/api/v4/projects/"
    .. git_info.owner
    .. "%2F"
    .. git_info.repo
    .. "/ci/lint"
  curl.post(url, {
    body = get_payload ".gitlab-ci.yml",
    headers = { Content_Type = "application/json", Authorization = "Bearer " .. token },
    callback = function(response)
      curl_callback(response)
    end,
    on_error = function(err)
      vim.notify("Error: " .. err.message, vim.log.levels.ERROR)
    end,
  })
end

local function check_creds()
  if token == nil then
    return false, "GITLAB_API_TOKEN or GITLAB_TOKEN need to be set, please set one"
  else
    return true
  end
end

local function validate()
  local ok, msg = check_creds()
  if ok then
    validate_job()
  else
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

return {
  validate = validate,
  check_creds = check_creds,
}
