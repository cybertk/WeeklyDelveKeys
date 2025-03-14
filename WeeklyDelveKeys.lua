local addonName, WeeklyDelveKeys = ...

WeeklyDelveKeys.frame = CreateFrame("Frame")

WeeklyDelveKeys.frame:SetScript("OnEvent", function(self, event, ...)
	WeeklyDelveKeys.eventsHandler[event](event, ...)
end)

function WeeklyDelveKeys:RegisterEvent(name, handler)
	if self.eventsHandler == nil then
		self.eventsHandler = {}
	end
	self.eventsHandler[name] = handler
	self.frame:RegisterEvent(name)
end

local EligibleItems = {
	239118, -- Pinnacle Cache
	239125, -- The weaver's Gratuity
	239122, -- The general's War Chest
	239124, -- The vizier's Capital
	239128, -- Theater Troupe's Trove
	239126, -- Radiant Cache
	239121, -- Awakened Mechanical Cache
	235610, -- Seasoned Adventurer's Cache - S2
	235639, -- Seasoned Adventurer's Cache - S2
	238208, -- Nanny's Surge Dividends
	239120, -- Seasoned Adventurer's Cache
}

function EligibleItems:Init()
	self.cache = {}
	for _, item in ipairs(self) do
		self.cache[item] = true
	end
end

function EligibleItems:Contain(itemID)
	return self.cache[itemID] == true
end

local DELVE_KEY_CURRENCY_ID = 3028

local Progress = {
	required = 4,
	remaining = { 84736, 84737, 84738, 84739 },
}

function Progress:Update()
	for i = #self.remaining, 1, -1 do
		if C_QuestLog.IsQuestFlaggedCompleted(self.remaining[i]) then
			table.remove(self.remaining, i)
		end
	end
end

function Progress:Summary()
	local color = #self.remaining == 0 and GREEN_FONT_COLOR or WHITE_FONT_COLOR

	return color:WrapTextInColorCode(format("%d/%d", self.required - #self.remaining, self.required))
end

function Progress:Init()
	local currency = C_CurrencyInfo.GetCurrencyInfo(DELVE_KEY_CURRENCY_ID)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if not EligibleItems:Contain(tooltip:GetPrimaryTooltipData().id) then
			return
		end

		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(
			format(CURRENCY_THIS_WEEK, ITEM_QUALITY_COLORS[currency.quality].color:WrapTextInColorCode("[" .. currency.name .. "]")),
			self:Summary(),
			1,
			1,
			1
		)
	end)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
		if tooltip:GetPrimaryTooltipData().id ~= DELVE_KEY_CURRENCY_ID then
			return
		end
		tooltip:AddLine(format(CURRENCY_WEEKLY_CAP, "|cnWHITE_FONT_COLOR:", self.required - #self.remaining, self.required .. "|r"))
	end)
end

WeeklyDelveKeys:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
	if isInitialLogin == false and isReloadingUi == false then
		return
	end

	EligibleItems:Init()
	C_Timer.After(1, function()
		Progress:Init()
	end)
end)

WeeklyDelveKeys:RegisterEvent("QUEST_LOG_UPDATE", function()
	Progress:Update()
end)
