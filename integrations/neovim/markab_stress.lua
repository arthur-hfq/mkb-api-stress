-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] NEOVIM INTEGRATION FOR API-STRESS                      ║
-- ╚══════════════════════════════════════════════════════════════════╝

local M = {}

-- Create a brutalist floating panel for output streaming
local function create_panel(title)
  local buf = vim.api.nvim_create_buf(false, true)
  local w = math.floor(vim.o.columns * 0.85)
  local h = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = " [q] Close | [Esc] Exit ",
    footer_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = true
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })

  return buf, win
end

local function run_async(cmd, buf)
  local all_lines = { "┌─ EXECUTING STRESS TEST ─────────────────────────┐", "  " .. cmd, "└─────────────────────────────────────────────────┘", "", "Waiting for container startup & benchmark output..." }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)

  vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(all_lines, line) end
        end
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(all_lines, "[STDERR] " .. line) end
        end
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
          end
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          table.insert(all_lines, "")
          table.insert(all_lines, string.format("Exit Code: %d (%s)", code, code == 0 and "SUCCESS" or "FAILURE"))
          vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
        end
      end)
    end,
  })
end

--- Launch the interactive Neovim wizard for api-stress
function M.stress_test()
  local project_dir = vim.fn.getcwd()
  local default_cmd = "node index.js"
  if vim.fn.filereadable(project_dir .. "/package.json") == 1 then
    default_cmd = "npm run dev"
  elseif vim.fn.filereadable(project_dir .. "/main.go") == 1 then
    default_cmd = "go run main.go"
  elseif vim.fn.filereadable(project_dir .. "/app.py") == 1 or vim.fn.filereadable(project_dir .. "/main.py") == 1 then
    default_cmd = "python app.py"
  end

  vim.ui.select({ "0.25 CPU / 128MB RAM", "0.5 CPU / 256MB RAM", "1.0 CPU / 512MB RAM", "2.0 CPU / 1GB RAM" }, {
    prompt = "Container Resource Constraints:",
  }, function(res_choice)
    if not res_choice then return end
    local cpus = res_choice:match("^([%d%.]+)%s+CPU") or "0.5"
    local mem = res_choice:match("/%s+([%w]+)%s+RAM") or "256m"

    vim.ui.input({ prompt = "Server Start Command: ", default = default_cmd }, function(start_cmd)
      if not start_cmd or start_cmd == "" then return end

      vim.ui.input({ prompt = "Internal Container Port: ", default = "3000" }, function(port)
        if not port or port == "" then return end

        vim.ui.input({ prompt = "Route: ", default = "/" }, function(route)
          if not route or route == "" then return end

          vim.ui.select({ "GET", "POST", "PUT", "DELETE", "PATCH" }, { prompt = "HTTP Method: " }, function(method)
            if not method then return end

            vim.ui.input({ prompt = "Total Requests: ", default = "100" }, function(count)
              if not count or count == "" then return end

              vim.ui.input({ prompt = "Concurrency: ", default = "10" }, function(conc)
                if not conc or conc == "" then return end

                local exec_bin = vim.fn.exepath("api-stress")
                if exec_bin == "" then
                  exec_bin = vim.fn.expand("~/.local/bin/api-stress")
                end

                local cmd = string.format("%s -d %s -c %s -m %s -s %q -p %s -r %q -X %s -n %s -C %s",
                  exec_bin, vim.fn.shellescape(project_dir), cpus, mem, start_cmd, port, route, method, count, conc)

                local buf, _ = create_panel("DOCKER STRESS TEST — " .. method .. " " .. route)
                run_async(cmd, buf)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

return M
