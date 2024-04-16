_G.lazy = setmetatable({}, {
  __index = function(_, key)
    return require("panel." .. key)
  end,
})
