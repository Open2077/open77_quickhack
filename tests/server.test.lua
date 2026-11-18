-- Server rules of open77_quickhack, without a host: the Open77 surface, exports, events and
-- timers are stubbed here. Run: python tests/run.py (lupa, Lua 5.4).

local clock, timers = 0, {}
local sent, fired, exported, hooks = {}, {}, {}, {}
local positions, names = {}, {}
local netHandlers = {}

function GetGameTimer() return clock end
function GetCurrentResourceName() return "open77_quickhack" end
local invoking = "test_owner"
function GetInvokingResource() return invoking end
function SetTimeout(ms, fn) timers[#timers + 1] = { at = clock + ms, fn = fn } end
function TriggerClientEvent(name, pid, payload) sent[#sent + 1] = { name = name, pid = pid, payload = payload } end
function TriggerEvent(name, ...) fired[#fired + 1] = { name = name, args = { ... } } end
function RegisterNetEvent(name, fn) netHandlers[name] = fn end
function AddEventHandler() end
function exports(name, fn) exported[name] = fn end
function print() end

local sounds = {}
Open77 = {
    effects = { sound = function(target, event) sounds[#sounds + 1] = { target = target, event = event }; return true end },
    players = {
        position = function(pid) return positions[pid] end,
        name = function(pid) return names[pid] end,
        get = function(pid) return positions[pid] and { speed = 3, heading = 90 } or nil end,
    },
    npcs = {
        get = function(id) return nil end,                                  -- this resource owns no NPC
        presence = function(id) if id == 900 then return { id = 900, x = 8, y = 0, z = 0, bucket = 0, alive = true, resource = "gangs" } end end,
        all = function() return { { id = 900, record = "Character.maelstrom_grunt1_ranged1_ajax_wa", resource = "gangs", health = 80, maxHealth = 100 } } end,
    },
    vehicles = {
        get = function(id) if id == 55 then return { id = 55, x = 6, y = 0, z = 0, bucket = 0, record = "Vehicle.v_sport2_quadra_type66",
            health = 0.75, speedKph = 12, locked = true, occupants = { { playerId = 2 } }, resource = "garage" } end end,
        getPlayerSeat = function() return nil end,
    },
    exports = {
        callSync = function(owner, name, ctx) return (hooks[name] or exported[name])(ctx) end,
        call = function(owner, name, ctx) (hooks[name] or exported[name])(ctx); return {} end,
    },
}

local function advance(ms)
    clock = clock + ms
    local due = {}
    for i = #timers, 1, -1 do if timers[i].at <= clock then due[#due + 1] = table.remove(timers, i) end end
    for _, t in ipairs(due) do t.fn() end
end

local function net(name, pid, payload) source = pid; netHandlers[name](payload) end
local function last(name, pid)
    for i = #sent, 1, -1 do if sent[i].name == name and (pid == nil or sent[i].pid == pid) then return sent[i].payload end end
end

dofile(ROOT .. "/shared/config.lua")
dofile(ROOT .. "/shared/presets.lua")
QuickhackConfig.deck.regen = 0
dofile(ROOT .. "/server/main.lua")
dofile(ROOT .. "/server/examples.lua")

local results, failures = {}, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    results[#results + 1] = (ok and "PASS " or "FAIL ") .. name .. (ok and "" or (": " .. tostring(err)))
    if not ok then failures = failures + 1 end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end

positions[1] = { x = 0, y = 0, z = 0, bucket = 0 }
positions[2] = { x = 10, y = 0, z = 0, bucket = 0 }
names[1], names[2] = "Hacker", "Victim"
local executed = {}
hooks.gate = function(ctx) if ctx.quickhack == "cyberpsychosis" then return false, "immune" end; return true end
hooks.run = function(ctx) executed[#executed + 1] = ctx end

test("register validates and owns ids", function()
    eq(exported.registerPreset("short_circuit", { canUse = "gate", onExecute = "run" }), true)
    eq(exported.registerPreset("cyberpsychosis", { canUse = "gate", onExecute = "run" }), true)
    eq(exported.register({ id = "Bad Id" }), false)
    invoking = "someone_else"
    local ok, why = exported.register({ id = "short_circuit" })
    eq(ok, false); eq(why, "id_taken")
    invoking = "test_owner"
    advance(100)
    local cat = last("open77_quickhack:catalogue", -1)
    eq(#cat.quickhacks, 6, "catalogue broadcast (2 + the 4 example pings)")
end)

test("scan returns target data and offers with gate reasons", function()
    exported.setPlayerInfo(2, { affiliation = "Afterlife", bounty = 10, abilities = { { label = "Stim", icon = "overload" } } })
    net("open77_quickhack:scan", 1, { seq = 7, target = { kind = "player", id = 2 } })
    local r = last("open77_quickhack:scanResult", 1)
    eq(r.ok, true); eq(r.seq, 7); eq(r.target.name, "Victim"); eq(r.target.info.affiliation, "Afterlife")
    local states = {}
    for _, o in ipairs(r.offers) do states[o.id] = o end
    eq(states.short_circuit.state, "ready")
    eq(states.cyberpsychosis.state, "blocked"); eq(states.cyberpsychosis.reason, "immune")
end)

test("self and out of range are refused", function()
    net("open77_quickhack:scan", 1, { seq = 8, target = { kind = "player", id = 1 } })
    eq(last("open77_quickhack:scanResult", 1).reason, "self")
    positions[2] = { x = 500, y = 0, z = 0, bucket = 0 }
    net("open77_quickhack:scan", 1, { seq = 9, target = { kind = "player", id = 2 } })
    eq(last("open77_quickhack:scanResult", 1).reason, "out_of_range")
    positions[2] = { x = 10, y = 0, z = 0, bucket = 0 }
end)

test("execute spends RAM, warns the victim, and completes after the upload", function()
    local before = exported.getDeck(1).ram
    net("open77_quickhack:execute", 1, { seq = 10, target = { kind = "player", id = 2 }, quickhack = "short_circuit" })
    eq(last("open77_quickhack:executeResult", 1).ok, true)
    eq(exported.getDeck(1).ram, before - 5)
    local warn = last("open77_quickhack:incoming", 2)
    eq(warn.label, "Short Circuit"); eq(warn.from, "Hacker")
    net("open77_quickhack:execute", 1, { seq = 11, target = { kind = "player", id = 2 }, quickhack = "short_circuit" })
    eq(last("open77_quickhack:executeResult", 1).reason, "upload_in_progress")
    advance(1600)
    eq(last("open77_quickhack:uploadEnd", 1).ok, true)
    eq(last("open77_quickhack:incomingEnd", 2).ok, true)
    eq(#executed, 1); eq(executed[1].target.id, 2)
    eq(#sounds, 1); eq(sounds[1].event, "quickhack_shortcircuit"); eq(sounds[1].target.kind, "player"); eq(sounds[1].target.id, 2)
end)

test("cooldown and RAM gate the next use", function()
    net("open77_quickhack:execute", 1, { seq = 12, target = { kind = "player", id = 2 }, quickhack = "short_circuit" })
    eq(last("open77_quickhack:executeResult", 1).ok, false, "cooldown")
    advance(9000)
    exported.setRam(1, 2)
    net("open77_quickhack:execute", 1, { seq = 13, target = { kind = "player", id = 2 }, quickhack = "short_circuit" })
    eq(last("open77_quickhack:executeResult", 1).reason, "insufficient_ram")
    exported.setRam(1, 19)
end)

test("gate refusal blocks execute", function()
    net("open77_quickhack:execute", 1, { seq = 14, target = { kind = "player", id = 2 }, quickhack = "cyberpsychosis" })
    eq(last("open77_quickhack:executeResult", 1).reason, "immune")
end)

test("a target that leaves range fails the upload", function()
    net("open77_quickhack:execute", 1, { seq = 15, target = { kind = "player", id = 2 }, quickhack = "short_circuit" })
    eq(last("open77_quickhack:executeResult", 1).ok, true)
    positions[2] = { x = 400, y = 0, z = 0, bucket = 0 }
    advance(1600)
    local r = last("open77_quickhack:uploadEnd", 1)
    eq(r.ok, false); eq(r.reason, "out_of_range")
    positions[2] = { x = 10, y = 0, z = 0, bucket = 0 }
end)

test("points: registered, restricted list, owner-only removal", function()
    eq(exported.registerPreset("breach_protocol", { onExecute = "run" }), true)
    local ok = exported.addTarget({ kind = "point", id = "term1", position = { x = 3, y = 0, z = 1 }, name = "Terminal",
        tone = "device", quickhacks = { "breach_protocol" } })
    eq(ok, true)
    net("open77_quickhack:scan", 1, { seq = 16, target = { kind = "point", id = "term1" } })
    local r = last("open77_quickhack:scanResult", 1)
    eq(r.ok, true); eq(r.target.name, "Terminal"); eq(r.target.tone, "device"); eq(#r.offers, 1); eq(r.offers[1].id, "breach_protocol")
    invoking = "intruder"
    eq(exported.removeTarget("term1"), false)
    invoking = "test_owner"
    eq(exported.removeTarget("term1"), true)
end)

test("an owned NPC is located through the owner's locate export", function()
    hooks.where = function(t) return { x = 12, y = 0, z = 0, bucket = 0 } end
    eq(exported.addTarget({ kind = "npc", id = 77, name = "Merc", tone = "hostile", locate = "where" }), true)
    net("open77_quickhack:scan", 1, { seq = 30, target = { kind = "npc", id = 77 } })
    local r = last("open77_quickhack:scanResult", 1)
    eq(r.ok, true); eq(r.target.name, "Merc")
    hooks.where = function() return nil end
    net("open77_quickhack:scan", 1, { seq = 31, target = { kind = "npc", id = 77 } })
    eq(last("open77_quickhack:scanResult", 1).reason, "target_gone")
end)

test("vehicles and another resource's NPCs are automatic targets", function()
    net("open77_quickhack:scan", 1, { seq = 40, target = { kind = "vehicle", id = 55 } })
    local r = last("open77_quickhack:scanResult", 1)
    eq(r.ok, true); eq(r.target.name, "QUADRA TYPE66"); eq(r.target.tone, "device")
    local ids = {}
    for _, o in ipairs(r.offers) do ids[o.id] = o.state end
    eq(ids.ping_vehicle, "ready"); eq(ids.ping_player, nil)
    net("open77_quickhack:scan", 1, { seq = 41, target = { kind = "npc", id = 900 } })
    r = last("open77_quickhack:scanResult", 1)
    eq(r.ok, true); eq(r.target.name, "GRUNT1 RANGED1 AJAX WA")
end)

test("the example Ping reports the target on the hacker's screen", function()
    exported.setRam(1, 19)
    net("open77_quickhack:execute", 1, { seq = 42, target = { kind = "vehicle", id = 55 }, quickhack = "ping_vehicle" })
    eq(last("open77_quickhack:executeResult", 1).ok, true)
    advance(900)
    local card = last("open77_quickhack:report", 1)
    eq(card.title, "PING // VEHICLE"); eq(card.subtitle, "QUADRA TYPE66")
    local fields = {}
    for _, f in ipairs(card.fields) do fields[f[1]] = f[2] end
    eq(fields.MODEL, "QUADRA TYPE66"); eq(fields.LOCKED, "YES"); eq(fields.OCCUPANTS, "Victim"); eq(fields.HEALTH, "75 %")
end)

test("the device Ping reports a point", function()
    eq(exported.addTarget({ kind = "point", id = "ping_me", position = { x = 4, y = 0, z = 0 }, name = "Router", tone = "device" }), true)
    net("open77_quickhack:execute", 1, { seq = 43, target = { kind = "point", id = "ping_me" }, quickhack = "ping_device" })
    eq(last("open77_quickhack:executeResult", 1).ok, true)
    advance(700)
    local card = last("open77_quickhack:report", 1)
    eq(card.title, "PING // DEVICE"); eq(card.subtitle, "ROUTER"); eq(card.tone, "device")
    exported.removeTarget("ping_me")
end)

test("the player Ping reports the player", function()
    net("open77_quickhack:execute", 1, { seq = 44, target = { kind = "player", id = 2 }, quickhack = "ping_player" })
    eq(last("open77_quickhack:executeResult", 1).ok, true)
    eq(last("open77_quickhack:incoming", 2).label, "Ping")
    advance(1100)
    local card = last("open77_quickhack:report", 1)
    local fields = {}
    for _, f in ipairs(card.fields) do fields[f[1]] = f[2] end
    eq(card.title, "PING // PLAYER"); eq(fields.NAME, "Victim"); eq(fields["PLAYER ID"], "2"); eq(fields.DISTANCE, "10.0 M")
end)

test("examples can be switched off", function()
    exported.setExamplesEnabled(false)
    advance(100)
    local ids = {}
    for _, d in ipairs(last("open77_quickhack:catalogue", -1).quickhacks) do ids[d.id] = true end
    eq(ids.ping_player, nil); eq(ids.short_circuit, true)
    exported.setExamplesEnabled(true)
end)

test("info is sanitised (lengths, counts, control characters)", function()
    local info = QuickhackServer.sanitizeInfo({ name = ("X"):rep(100), fields = { { "a", "b" }, { "c" } }, threat = "high",
        abilities = { "One", "Two", "Three", "Four", "Five", "Six", "Seven" }, affiliation = "line\nbreak" })
    eq(#info.name, 48); eq(#info.fields, 1); eq(info.threat, 3); eq(#info.abilities, 6); eq(info.affiliation, "line break")
end)

for _, line in ipairs(results) do io.write(line, "\n") end
io.write(("%d tests, %d failed\n"):format(#results, failures))
return failures
