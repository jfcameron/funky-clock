---------------------------------------------------------------------------
-- A clock widget that is decorated by a user provided functor
--
-- @usage
-- local funkyclock = require("path.to.funkyclock")
-- 
-- clock = funkyclock(function(aYear, aMonth, aDay, aWeekday, aHour, aMinute)
-- 	WEEKDAY = {
-- 		["1"] = "月",
-- 		["2"] = "火",
-- 		["3"] = "水",
-- 		["4"] = "木",
-- 		["5"] = "金",
-- 		["6"] = "土",
-- 		["7"] = "日",
-- 	}
-- 
-- 	return aYear .. "年" .. aMonth .. "月" .. aDay .. "日" .. 
-- 		"(" .. WEEKDAY[aWeekday] .. ")" .. aHour .. ":" .. aMinute
-- end)
--
-- @author jfcameron
-- @copyright 2020
---------------------------------------------------------------------------
local wibox = {
	widget= {
		textbox = require("wibox.widget.textbox")
	}
}
local gears = {
	timer = require("gears.timer"),
	table = require("gears.table")
}
local lgi = {
	GLib = {
		DateTime = require("lgi").GLib.DateTime,
		TimeZone = require("lgi").GLib.TimeZone
	}
}
local setmetatable = setmetatable
local os = os

local funkyclock = { mt = {} }

--- creates a new funkyclock widget
--
-- @tparam functor takes year, month, day, weekday, hour, minute, all as string params, 
-- returns a string, to be rendered in the clock's textbox
-- for reference, look at the default functor in the new function
--
-- @tparam[opt=local timezone] string timezone The timezone ID to use. Format:
-- https://developer.gnome.org/glib/stable/glib-GTimeZone.html#g-time-zone-new.
--
-- @treturn a new funkyclock instance
local function new(aDecorator, aTimeZoneID)
	local textbox = wibox.widget.textbox()
	gears.table.crush(textbox, funkyclock, true)

	textbox._private.decorator = aDecorator or function(aYear, aMonth, aDay, aWeekday, aHour, aMinute)
		return aYear .. "-" .. aMonth .. "-" .. aDay .. "T" .. aHour .. ":" .. aMinute
	end 

	textbox._private.timezone = aTimeZoneID and lgi.GLib.TimeZone.new(aTimeZoneID) or lgi.GLib.TimeZone.new_local()

	local REFRESH = 60

	function textbox._private.update()
		local dateTime = lgi.GLib.DateTime.new_now(textbox._private.timezone)

		local weekday = dateTime:format("%u") -- "1" - "7"
		local year = dateTime:format("%Y") -- "YYYY"
		local month = dateTime:format("%m") -- "MM"
		local day = dateTime:format("%d") -- "DD"
		local hour = dateTime:format("%H") -- "HH"
		local minute = dateTime:format("%M") -- "MM"

		textbox:set_markup(textbox._private.decorator(year, month, day, weekday, hour, minute))
		textbox._timer.timeout = REFRESH - os.time() % REFRESH
		textbox._timer:again()

		return true
	end

	textbox._timer = gears.timer.weak_start_new(REFRESH, textbox._private.update)
	textbox._timer:emit_signal("timeout")

	return textbox
end

function funkyclock.mt:__call(...)
	return new(...)
end

return setmetatable(funkyclock, funkyclock.mt)

