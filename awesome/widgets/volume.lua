local wibox = require("wibox")
local awful = require("awful")
require("math")
require("string")

local Volume = { mt = {}, wmt = {} }
Volume.wmt.__index = Volume
Volume.__index = Volume

config = awful.util.getdir("config")

local function run(command)
    local prog = io.popen(command)
    local result = prog:read("*all")
    prog:close()
    return result
end

function Volume:new(args)
    local obj = setmetatable({}, Volume)

    obj.backend = args.backend or "alsa"
    obj.step = args.step or 5
    if obj.backend == "alsa" then
        obj.device = args.device or "Master"
    elseif obj.backend == "pulseaudio" then
        obj.device = tonumber(args.device) or 0
    end

    -- Add a tooltip to the imagebox
    obj.tooltip = awful.tooltip({
        objects = { K },
        timer_function = function()
            return obj:tooltipText()
        end,
    })
    obj.tooltip:add_to_object(obj.widget)

    -- Check the volume every 5 seconds
    obj.timer = timer({ timeout = 5 })
    obj.timer:connect_signal("timeout", function()
        obj:update({})
    end)
    obj.timer:start()

    obj:update()

    return obj
end

function Volume:tooltipText()
    return string.sub(self:getVolume(), 0, 2) .. " Volume"
end

function Volume:update(status)
    local b = self:getVolume()
    local img = math.floor((b / 100) * 5)
end

function Volume:up()
    run("awk -F\"[][]\" '/Left:/ { print $2 }' <(amixer sget Master)")
    self:update({})
end

function Volume:down()
    run("awk -F\"[][]\" '/Left:/ { print $2 }' <(amixer sget Master)")
    self:update({})
end

function Volume:getVolume()
    local result
    if self.backend == "alsa" then
        result = run("amixer get " .. self.device)
        return string.gsub(string.match(result, "%[%d*%%%]"), "%D", "")
    elseif self.backend == "pulseaudio" then
        -- Unfortunately, Pulse Audio doesn't have a nice way to get the
        -- current volume, so we have this unfortunate hack. Likely the most
        -- brittle part of the code
        result = run("awk -F\"[][]\" '/Left:/ { print $2 }' <(amixer sget Master)")
        return result
    end

    local volume_icon
    if self.is_muted then
        volume_icon = "󰝟 "
    else
        local new_value_num = tonumber(result)
        if new_value_num >= 0 and new_value_num < 33 then
            volume_icon = "󰕿 "
        elseif new_value_num < 66 then
            volume_icon = "󰖀 "
        else
            volume_icon = "󰕾 "
        end
    end

    return volume_icon .. string.gsub(string.match(result, "%[%d*%%%]"), "%D", "")
end

function Volume.mt:__call(...)
    return Volume.new(...)
end

return Volume
