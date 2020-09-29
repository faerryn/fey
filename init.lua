local config_d = vim.fn.expand'$XDG_CONFIG_HOME'
if config_d == '' then
	config_d = vim.fn.expand'$HOME/.config'
end

local data_d = vim.fn.expand'$XDG_DATA_HOME'
if data_d == '' then
	data_d = vim.fn.expand'$HOME/.local/share'
end

vim.o.packpath = data_d .. '/fey,' .. vim.o.packpath

if vim.g.batch ~= nil then
	vim.cmd'packadd minpac'

	minpac = {
		init = vim.fn['minpac#init'],
		add = vim.fn['minpac#add'],
		update = vim.fn['minpac#update'],
		clean = vim.fn['minpac#clean'],
		getplugininfo = vim.fn['minpac#getplugininfo'],
		getpluginlist = vim.fn['minpac#getpluginlist'],
		getpackages = vim.fn['minpac#getpackages'],
		status = vim.fn['minpac#status'],
	}

	minpac.init{ confirm = false }
	minpac.add('k-takata/minpac', {type = 'opt'})
end

vim.cmd'augroup fey_reload'
vim.cmd'augroup END'

function load_file_lenient(file)
	if vim.fn.filereadable(file) == 0 then return end
	local status, result = pcall(dofile, file)
	if not status then
		print(result)
		return nil
	end
	return result
end

fey = {}

if vim.g.batch ~= nil then
	function fey_load_module(module_d, name)
		load_file_lenient(module_d .. '/packages.lua')
	end
else
	function fey_load_module(module_d, name)
		fey[name] = {}

		local config_f = module_d .. '/config.lua'
		vim.cmd('autocmd! fey_reload BufWritePost ' .. vim.fn.resolve(config_f) .. " lua fey_load_module('" .. module_d .. "', '" .. name .. "')")

		local augroup = 'fey_' .. name
		vim.cmd('augroup ' .. augroup)
		vim.cmd('autocmd! ' .. augroup)

		load_file_lenient(config_f)

		vim.cmd('augroup END')
	end
end

fey_core_d = vim.fn.expand('<sfile>:p:h')
fey_load_module(fey_core_d, 'core')

fey_user_d = config_d .. '/fey'
fey_load_module(fey_user_d, 'user')

local init_f = fey_user_d .. '/init.lua'
local core_module_d = fey_core_d .. '/modules'
local user_modules_d = fey_user_d .. '/modules'

for category, modules in pairs(dofile(init_f)) do
	for _, module in ipairs(modules) do
		local module_d = user_modules_d .. '/' .. category .. '/' .. module
		if vim.fn.isdirectory(module_d) == 0 then
			module_d = core_module_d .. '/' .. category .. '/' .. module
		end
		fey_load_module(module_d, category .. '_' .. module)
	end
end
