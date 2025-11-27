#!/bin/bash
node -e "
const fs = require('fs');
const m = JSON.parse(fs.readFileSync('src/chimera/manifest.json', 'utf8'));
const handshake = m.handshake.toUpperCase();
const focus = m.focus.toUpperCase();
const status = m.targets[m.focus].toUpperCase();
console.log(handshake + ':' + m.handshake.split('')[0].toUpperCase() + m.handshake.slice(1).split('').join('').toUpperCase() + '|' + focus + ':' + status);
"
