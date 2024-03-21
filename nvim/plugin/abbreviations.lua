-- inoreabbrev insert mode abbreviations
-- iabbrev insert and command line mode abbreviations

vim.cmd [[
inoreabbrev seperate separate
inoreabbrev dont don't
inoreabbrev cant can't
inoreabbrev teh the
inoreabbrev heigth height
inoreabbrev widht width
inoreabbrev waht what
inoreabbrev tehn then
inoreabbrev adn and
inoreabbrev tihs this
iabbrev <expr> ,d strftime('%Y-%m-%d')
iabbrev <expr> ,t strftime('%Y-%m-%dT%TZ')
inoreabbrev <expr> ,u system('uuidgen')->trim()->tolower()
]]
