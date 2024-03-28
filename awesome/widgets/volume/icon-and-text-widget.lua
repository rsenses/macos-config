local wibox = require("wibox")
local beautiful = require("beautiful")

local widget = {}

function widget.get_widget(widgets_args)
    local args = widgets_args or {}

    local font = args.font or beautiful.font

    return wibox.widget({
        {
            valign = "center",
            layout = wibox.container.place,
        },
        {
            id = "txt",
            font = font,
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
        set_volume_level = function(self, new_value)
            local volume_icon
            if self.is_muted then
                volume_icon = "󰝟 "
            else
                local new_value_num = tonumber(new_value)
                if new_value_num >= 0 and new_value_num < 33 then
                    volume_icon = "󰕿 "
                elseif new_value_num < 66 then
                    volume_icon = "󰖀 "
                else
                    volume_icon = "󰕾 "
                end
            end
            self:get_children_by_id("txt")[1]:set_text(volume_icon .. new_value)
        end,
        mute = function(self)
            self.is_muted = true
            self:get_children_by_id("txt")[1]:set_text("󰝟 ")
        end,
        unmute = function(self)
            self.is_muted = false
        end,
    })
end

return widget
