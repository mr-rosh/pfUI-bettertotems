pfUI:RegisterModule("bettertotems", "vanilla:tbc", function()
    local _, class = UnitClass("player")

    local slots = {
      [FIRE_TOTEM_SLOT]  = { r = .5, g = .2, b = .1 },
      [EARTH_TOTEM_SLOT] = { r = .2, g = .4, b = .1 },
      [WATER_TOTEM_SLOT] = { r = .1, g = .4, b = .6 },
      [AIR_TOTEM_SLOT]   = { r = .4, g = .1, b = .7 },
    }
    -- Precompute color tables to avoid repeated field lookups in RefreshList.
    local slotColors = {}
    for i, color in pairs(slots) do
      slotColors[i] = { color.r, color.g, color.b }
    end

    local totems = CreateFrame("Frame", "pfBetterTotems", UIParent)
    totems:RegisterEvent("PLAYER_TOTEM_UPDATE")
    totems:RegisterEvent("PLAYER_ENTERING_WORLD")
    totems:SetScript("OnEvent", function(self, event, arg1)
      -- event/arg1 captured as parameters (Classic 1.12-safe).
      totems:RefreshList()
    end)

    if pfUI.client <= 11200 and class == "SHAMAN" then
      -- there's no totem event in vanilla; poll every 0.5s instead.
      local eventemu = CreateFrame("Frame")
      eventemu:SetScript("OnUpdate", function(self, elapsed)
        if (self.tick or 1) > GetTime() then return end
        self.tick = GetTime() + .5
        totems:RefreshList()
      end)
    end

    totems.OnEnter = function(self)
      local id = self.id
      if not id then return end
      local active, name, start, duration, icon, unitId = GetBetterTotemInfo(id)
      if not name then return end
      local color = slots[id]
      if not color then return end
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:SetText(name, color.r + .2, color.g + .2, color.b + .2)
      GameTooltip:Show()
    end

    totems.OnLeave = function(self)
      GameTooltip:Hide()
    end

    totems.OnClick = function(self, button)
      -- button is passed as arg1 in 1.12; capture via parameter.
      local id = self.id
      if not id then return end
      if pfUI.client <= 11200 and button == "LeftButton" then
        -- Try to recast totem on left click in vanilla
        local active, name, start, duration, icon, unitId = GetBetterTotemInfo(id)
        if name then CastSpellByName(name) end
      elseif pfUI.client > 11200 and button == "RightButton" then
        -- Try to cancel totem on right click in tbc+
        DestroyTotem(id)
      end
    end

    totems.RefreshList = function(self)
      local count = 0
      local totemicMastery = LibBetterTotem.HasTotemicMastery()
      local inRangeMastery = totemicMastery and 30 or 20

      -- Cache recall settings once per refresh instead of per-totem.
      local recallEnabled = (pfUI_config.bettertotems and pfUI_config.bettertotems.recall or "1") == "1"
      local recallRange = pfUI_config.bettertotems and tonumber(pfUI_config.bettertotems.recallRange) or 45

      for i = 1, MAX_TOTEMS do
        local activeFlag, name, start, duration, icon, unitId = GetBetterTotemInfo(i)

        if activeFlag and icon and icon ~= "" then
          count = count + 1
          local bar = self.bar[count]
          local color = slotColors[i]

          bar:Show()
          bar:SetBackdropBorderColor(color[1], color[2], color[3])
          bar.icon:SetTexture(icon)
          bar.id = i

          local inRange = LibrangeCalc:InRange(unitId, inRangeMastery)
          if not inRange and UnitExists(unitId) then
            bar.icon:SetVertexColor(1, 0, 0, 0.7)
            if recallEnabled and unitId and UnitExists(unitId) then
              local notWarnRange = LibrangeCalc:InRange(unitId, recallRange)
              if not notWarnRange then
                UIErrorsFrame:AddMessage("Totems Out of Range. Recall?", 1.0, 0.0, 0.0)
                PlaySound("igPVPUpdate", "master")
              end
            end
          else
            bar.icon:SetVertexColor(1, 1, 1, 1)
          end

          if bar.cd then
            CooldownFrame_SetTimer(bar.cd, start, duration, 1)
          end
        end
      end

      self:UpdateSize(count)
    end

    totems.UpdateSize = function(self, count)
      if not count or count == 0 then
        -- hide entire panel
        self:Hide()
      else
        -- hide remaining totems and show panel
        for i = count + 1, MAX_TOTEMS do self.bar[i]:Hide() end
        self:Show()
      end

      local barCount = count and count > 0 and count or MAX_TOTEMS

      if pfUI_config.totems.direction == "HORIZONTAL" then
        self:SetHeight(self.iconsize + self.spacing * 2)
        self:SetWidth(self.spacing * 2 + self.iconsize + (barCount - 1) * (self.iconsize + self.spacing * 2))
      else
        self:SetWidth(self.iconsize + self.spacing * 2)
        self:SetHeight(self.spacing * 2 + self.iconsize + (barCount - 1) * (self.iconsize + self.spacing * 2))
      end
    end

    totems.UpdateConfig = function(self)
      local rawborder, border = GetBorderSize()
      self.iconsize = pfUI_config.totems.iconsize
      self.direction = pfUI_config.totems.direction
      self.spacing = tonumber(pfUI_config.totems.spacing) * GetPerfectPixel()
      self.showbg = pfUI_config.totems.showbg == "1" and true or nil

      for i = 1, MAX_TOTEMS do
        self.bar = self.bar or {}
        self.bar[i] = self.bar[i] or CreateFrame("Button", "pfBetterTotemsBar" .. i, totems)
        self.bar[i]:ClearAllPoints()

        if pfUI_config.totems.direction == "HORIZONTAL" then
          if self.bar[i - 1] then
            self.bar[i]:SetPoint("LEFT", self.bar[i - 1], "RIGHT", self.spacing * 2, 0)
          else
            self.bar[i]:SetPoint("TOPLEFT", self, "TOPLEFT", self.spacing, -self.spacing)
          end
        else
          if self.bar[i - 1] then
            self.bar[i]:SetPoint("TOP", self.bar[i - 1], "BOTTOM", 0, -self.spacing * 2)
          else
            self.bar[i]:SetPoint("TOPLEFT", self, "TOPLEFT", self.spacing, -self.spacing)
          end
        end

        self.bar[i]:SetHeight(self.iconsize)
        self.bar[i]:SetWidth(self.iconsize)
        CreateBackdrop(self.bar[i], nil, true)

        self.bar[i].icon = self.bar[i].icon or self.bar[i]:CreateTexture(nil, "ARTWORK")
        self.bar[i].icon:SetTexCoord(.08, .92, .08, .92)
        SetAllPointsOffset(self.bar[i].icon, self.bar[i], 2, -2)

        self.bar[i].cdbg = self.bar[i].cdbg or CreateFrame("Frame", nil, self.bar[i])
        self.bar[i].cdbg:SetHeight(self.iconsize - 3)
        self.bar[i].cdbg:SetWidth(self.iconsize - 3)
        self.bar[i].cdbg:SetPoint("CENTER", self.bar[i], "CENTER", 0, 0)
        self.bar[i].cd = self.bar[i].cd or CreateFrame("Cooldown", "pfBetterTotemsBar" .. i .. "Cooldown", self.bar[i].cdbg, "CooldownFrameTemplate")
        self.bar[i].cd.pfCooldownStyleAnimation = 1
        self.bar[i].cd.pfCooldownType = "ALL"

        self.bar[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        self.bar[i]:SetScript("OnClick", self.OnClick)
        self.bar[i]:SetScript("OnEnter", self.OnEnter)
        self.bar[i]:SetScript("OnLeave", self.OnLeave)
      end

      self:RefreshList()
      self:ClearAllPoints()
      self:SetPoint("BOTTOM", 0, 75)
      UpdateMovable(self, true)

      if self.showbg then
        CreateBackdrop(self)
        self.backdrop:Show()
      elseif self.backdrop then
        self.backdrop:Hide()
      end
    end

    -- add totems to the pfUI global space
    BetterTotems = totems
    BetterTotems:UpdateConfig()
end)
