local M = {}

function M.setup()
  vim.api.nvim_create_user_command("PanelSwitch", function(opts)
    local tab = opts.fargs[1]
    lazy.manager.navigate(tab)
  end, {
    nargs = 1,
    complete = function()
      return vim
        .iter(lazy.config.opts.tabs)
        :map(function(v)
          return v.name
        end)
        :totable()
    end,
  })
end

return M
