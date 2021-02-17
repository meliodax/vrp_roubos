dependency "vrp_general" client_script "@vrp_general/client.lua" fx_version "adamant"
game "gta5" 

client_scripts {
	"@vrp/lib/utils.lua",
	"config.lua",
	"client.lua"
}

server_scripts {
	"@vrp/lib/utils.lua",
	"config.lua",
	"server.lua"
}
