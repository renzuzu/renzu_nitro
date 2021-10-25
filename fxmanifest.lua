fx_version 'cerulean'
game 'gta5'
ui_page 'html/index.html'
lua54 'on'
use_fxv2_oal 'on'
is_cfxv2 'yes'

shared_scripts {
	"config.lua"
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',	
	"server.lua"
}
client_scripts {
	"client.lua",
}

files {
	'html/index.html',
	'html/script.js',
}