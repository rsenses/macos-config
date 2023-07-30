return {
  "goolord/alpha-nvim",
  opts = function(_, dashboard)
    local logo = [[
oo__          _      _          __oo    ||     ·----·     ||
    """--,,,_(_)_--_(_)_,,,--"""        ||    /      \    ||
            _>_[____]_<_                ||=oo|        |oo=||
    ___--""" (_)\__/(_) """--___        ||    \      /    ||
oo""                            ""oo    ||     ·----·     ||
      ]]
    dashboard.section.header.val = vim.split(logo, "\n")
  end,
}
