game 'rdr3'
fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'Andyuk & RexshackGaming : Casino Vault Heist'

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_scripts {
    'config.lua'
}

dependency 'rsg-core' -- https://github.com/Rexshack-RedM/rsg-core
dependency 'rsg-inventory' -- https://github.com/Rexshack-RedM/rsg-inventory
dependency 'rsg-lawmen' -- https://github.com/Rexshack-RedM/rsg-lawman

lua54 'yes'