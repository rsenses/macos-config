-- inoreabbrev insert mode abbreviations
-- iabbrev insert and command line mode abbreviations

vim.cmd [[
iabbrev <expr> d@ strftime('%Y-%m-%d')
iabbrev <expr> t@ strftime('%Y-%m-%dT%TZ')
inoreabbrev <expr> u@ system('uuidgen')->trim()->tolower()
inoreabbrev adn and
inoreabbrev cant can't
inoreabbrev dont don't
inoreabbrev heigth height
inoreabbrev seperate separate
inoreabbrev teh the
inoreabbrev tehn then
inoreabbrev tihs this
inoreabbrev waht what
inoreabbrev widht width
inoreabbrev tempalte template
inoreabbrev resutl result
]]
