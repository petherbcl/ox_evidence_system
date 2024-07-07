fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "ox_evidence_system"
description "OX Lib based Evidence System"
author "petherbcl"
version "0.0.1"

dependencies {
    'ox_lib',
}

shared_scripts {
	'@ox_lib/init.lua',
	'@vrp/lib/utils.lua',
	'shared/*.lua'
}

client_scripts {
	'framework/**/client.lua',
	'client/*.lua'
}

server_scripts {
	'framework/**/server.lua',
	'server/*.lua'
}
