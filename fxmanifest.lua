
fx_version 'adamant'

game 'gta5'

author '😈 𝐀𝐍𝐔𝐄𝐋 𝐀𝐀 😈#6979'

descripcion 'Script para utilidades como: señalar, agacharse, quedarse K.O, que las armas quiten menos vida, etc etc etc'

fx_version '1.0'

discord 'https://discord.gg/ZdDBjyYr9x'

files({'**/**/**/**/**/**/*.*'})

client_script {
    'client.lua'
}

server_script {
    '@async/async.lua',
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server/init/*.lua',
    'server/lib/*.lua',
    'server/*.lua',
}

shared_scripts {
    'common.lua',
    'debug.lua',
}